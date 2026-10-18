//! Cumulative-amount Merkle proofs (sha256, domain-separated, sorted pairs).
//!
//! Derived from first principles (docs/V1_FEES.md section 4.1). No code is taken from the GPL
//! distributors (Jito, Saber, Uniswap). The sorted-pair node rule is the well-known scheme
//! also used by OpenZeppelin's MIT `MerkleProof`; only the idea is reused.
//!
//! ```text
//! leaf = sha256(0x00 || distributor (32) || claimant (32) || cumulative_amount (u64 LE))
//! node = sha256(0x01 || min(a, b) || max(a, b))        (byte-wise comparison)
//! ```
//!
//! - The 0x00 / 0x01 prefixes keep leaves and inner nodes in different domains, so a 64-byte
//!   node pre-image can never be presented as a leaf (second-preimage attack), and a leaf is
//!   73 bytes vs 65 for a node.
//! - The distributor address is in the leaf, so a proof for one (token, reward asset) pair
//!   never verifies against another distributor's root.
//! - Sorted pairs mean a proof is just the list of siblings, no left/right index.
//! - An odd node at a level is promoted unchanged (no self-pairing), so no duplicate leaves.
//!
//! The TypeScript twin is packages/sdk/src/merkle.ts; both are pinned by
//! fixtures/merkle-vectors.json (tests/merkle_vectors.rs and the SDK vitest).

use anchor_lang::prelude::Pubkey;
use solana_sha256_hasher::hashv;

pub const LEAF_PREFIX: u8 = 0x00;
pub const NODE_PREFIX: u8 = 0x01;
/// Hard cap on proof length: 2^32 leaves is far beyond any holder set.
pub const MAX_PROOF_LEN: usize = 32;

pub fn leaf_hash(distributor: &Pubkey, claimant: &Pubkey, cumulative_amount: u64) -> [u8; 32] {
    hashv(&[
        &[LEAF_PREFIX][..],
        distributor.as_ref(),
        claimant.as_ref(),
        &cumulative_amount.to_le_bytes()[..],
    ])
    .to_bytes()
}

pub fn node_hash(a: &[u8; 32], b: &[u8; 32]) -> [u8; 32] {
    let (l, r) = if a <= b { (a, b) } else { (b, a) };
    hashv(&[&[NODE_PREFIX][..], &l[..], &r[..]]).to_bytes()
}

/// Folds `proof` over `leaf` and compares with `root`.
pub fn verify(proof: &[[u8; 32]], root: &[u8; 32], leaf: [u8; 32]) -> bool {
    let mut h = leaf;
    for p in proof {
        h = node_hash(&h, p);
    }
    &h == root
}

/// Root of a list of leaf hashes (test/off-chain helper; the program only verifies).
pub fn root_of(leaves: &[[u8; 32]]) -> Option<[u8; 32]> {
    if leaves.is_empty() {
        return None;
    }
    let mut level: Vec<[u8; 32]> = leaves.to_vec();
    while level.len() > 1 {
        let mut next = Vec::with_capacity(level.len().div_ceil(2));
        for pair in level.chunks(2) {
            next.push(if pair.len() == 2 {
                node_hash(&pair[0], &pair[1])
            } else {
                pair[0]
            });
        }
        level = next;
    }
    Some(level[0])
}

/// Proof (siblings, bottom-up) for the leaf at `index` (test/off-chain helper).
pub fn proof_of(leaves: &[[u8; 32]], mut index: usize) -> Vec<[u8; 32]> {
    let mut proof = Vec::new();
    let mut level: Vec<[u8; 32]> = leaves.to_vec();
    while level.len() > 1 {
        let sib = index ^ 1;
        if sib < level.len() {
            proof.push(level[sib]);
        }
        let mut next = Vec::with_capacity(level.len().div_ceil(2));
        for pair in level.chunks(2) {
            next.push(if pair.len() == 2 {
                node_hash(&pair[0], &pair[1])
            } else {
                pair[0]
            });
        }
        level = next;
        index /= 2;
    }
    proof
}

#[cfg(test)]
mod tests {
    use super::*;

    fn pk(n: u8) -> Pubkey {
        Pubkey::new_from_array([n; 32])
    }

    #[test]
    fn single_leaf_root_is_the_leaf() {
        let l = leaf_hash(&pk(1), &pk(2), 5);
        assert_eq!(root_of(&[l]), Some(l));
        assert!(verify(&[], &l, l));
    }

    #[test]
    fn every_proof_verifies_and_tampering_fails() {
        for n in 1..=17usize {
            let d = pk(200);
            let leaves: Vec<[u8; 32]> = (0..n)
                .map(|i| leaf_hash(&d, &pk(i as u8), 1_000 + i as u64))
                .collect();
            let root = root_of(&leaves).unwrap();
            for (i, l) in leaves.iter().enumerate() {
                let p = proof_of(&leaves, i);
                assert!(verify(&p, &root, *l), "n={n} i={i}");
                // another amount, another claimant, another distributor: all fail
                assert!(!verify(&p, &root, leaf_hash(&d, &pk(i as u8), 1_001 + i as u64)));
                assert!(!verify(&p, &root, leaf_hash(&pk(201), &pk(i as u8), 1_000 + i as u64)));
                if n > 1 {
                    let mut bad = p.clone();
                    if let Some(first) = bad.first_mut() {
                        first[0] ^= 1;
                    }
                    assert!(!verify(&bad, &root, *l));
                }
            }
        }
    }

    #[test]
    fn inner_node_cannot_pose_as_a_leaf() {
        // A two-leaf tree's root is node(l0, l1). Presenting l0 || l1 as leaf data would need a
        // 0x00-prefixed pre-image equal to a 0x01-prefixed one: the domains never meet.
        let d = pk(9);
        let l0 = leaf_hash(&d, &pk(1), 1);
        let l1 = leaf_hash(&d, &pk(2), 2);
        let root = node_hash(&l0, &l1);
        // the node pre-image with the leaf prefix instead hashes to something else
        let as_leaf = hashv(&[&[LEAF_PREFIX][..], &l0.min(l1)[..], &l0.max(l1)[..]]).to_bytes();
        assert_ne!(as_leaf, root);
        assert!(!verify(&[], &root, as_leaf));
    }

    #[test]
    fn node_is_order_independent() {
        let a = [1u8; 32];
        let b = [2u8; 32];
        assert_eq!(node_hash(&a, &b), node_hash(&b, &a));
    }
}
