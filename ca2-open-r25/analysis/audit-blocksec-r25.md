---
firm: "BlockSec"
firm_id: "blocksec"
project: "R25"
audit_year: 2026
audit_date_min: "2026-04-28"
audit_date_max: "2026-04-28"
audit_date_basis: "report_issue"
audit_type: "protocol"
languages: ["unknown"]
chains: ["unknown"]
original_url: "https://github.com/blocksecteam/audit-reports/blob/9da368848d5a3b2a4e0f76a4e6dd04091de5d623/solidity/blocksec_r25_asyncvault_contracts_signed_20260428.pdf"
report_id: "2632908bf2bf46f83d212b778870d417c03040a9ba6556ee1583cc8b619ad225"
engagement_id: "engagement:39b4acb9aad8ba75495d38d2e0926e0f630e3550b3f9f40713ed7e5614f91f20"
severity_counts: {"critical": 0, "high": 0, "medium": 0, "low": 6, "info": 0, "gas": 0, "unknown": 0}
finding_records: 6
---

## "Incompatibility with the ERC-7540 standard"

finding_uid: "finding:06e31f944145f10877e7918672ae94ee7707af352f726772476c1b70ed6671e6"
finding_id: "2.1.5"
title: "Incompatibility with the ERC-7540 standard"
severity: "low"
status: "partially_fixed"
vuln_group: "logic_accounting"
vuln_leaf: "logic_accounting.integration"
engagement_id: "engagement:39b4acb9aad8ba75495d38d2e0926e0f630e3550b3f9f40713ed7e5614f91f20"
body_text_status: "present"
text_withheld: null
body_truncated: false
body_text_redactions: "{}"
text_attribution: null
text_license: null
text_license_url: null
text_source_url: null

<!-- body_text:start -->
    2.1.5 Incompatibility with the ERC-7540 standard

    Severity     Low
    Status     Partially Fixed in Version 2
    Introduced by      Version 1
    Description The contract AsyncVault declares itself as “ERC7540-compliant” (line 34). How-
    ever, the implementation is not fully compatible with ERC-7540 specification 2 and may break
    valid integrations.
         1. ERC-7540 vaults should return true for the ERC-165 interface IDs 0xe3bc4e65 and
    0x2f0a18c5. However, the implementation does not satisfy this requirement.
         2. ERC-7540 requires implementing the ERC-7575 interface as well. In particular, the
    vault must expose the function share() to return the share token address. The contract AsyncVault
    does not implement this function.
         3. ERC-7540 requires operator-related functionality. However, the contract AsyncVault
    only imports and inherits the interface IERC7540Redeem and does not implement the required
    functionality.
         4. The function claimableRedeemRequest() does not consider whether the required oracle
    report is available. When the oracle report is not ready, this function may still return a non-zero
    value, indicating that redemption is claimable even though the subsequent redemption process
    cannot be completed.
1852         /// @notice Checks if the contract supports the given interface.
1853         /// @param interfaceId The interface ID.
1854         /// @return True if the contract supports the interface, false otherwise.
1855         function supportsInterface(
1856             bytes4 interfaceId
1857         ) public view virtual override(AccessControlUpgradeable, ERC165Upgradeable) returns (bool) {
1858             return
1859                 interfaceId == bytes4(0x620ee8e4) ||
1860                 super.supportsInterface(interfaceId);
1861         }

    https://eips.ethereum.org/EIPS/eip-7540

                          Listing 2.6: src/r25-pc/AsyncVault/AsyncVault.sol

1425     function claimableRedeemRequest(
1426         uint256 requestId,
1427         address controller
1428     ) public view returns (uint256) {
1429         // 1. Verify request exists and belongs to controller
1430         RedeemRequestDetail memory request = redeemRequests[requestId];
1431         if (request.controller != controller) {
1432             return 0;
1433         }

1435          // 2. Check if in claimable state (based on time)
1436          if (block.timestamp >= request.unlockTime) {
1437              return request.shares;
1438          }
1439          return 0;
1440     }

                          Listing 2.7: src/r25-pc/AsyncVault/AsyncVault.sol

Impact This incompatibility may cause failed integrations and incorrect redemption assump-
tions for standards-based integrators.
Suggestion        Revise the logic accordingly.
Feedback from the project The project indicated that they temporarily do not support oper-
ator methods of ERC-7540 and the related interface ID (i.e., 0xe3bc4e65).


<!-- body_text:end -->

## "Incorrect implementation of ERC-4626 maximum limit functions"

finding_uid: "finding:787e6e507d213f49261509269d870ba986132ce04ee2c00d0ba3d6f53f5c805f"
finding_id: "2.1.4"
title: "Incorrect implementation of ERC-4626 maximum limit functions"
severity: "low"
status: "partially_fixed"
vuln_group: "logic_accounting"
vuln_leaf: "logic_accounting.integration"
engagement_id: "engagement:39b4acb9aad8ba75495d38d2e0926e0f630e3550b3f9f40713ed7e5614f91f20"
body_text_status: "present"
text_withheld: null
body_truncated: false
body_text_redactions: "{}"
text_attribution: null
text_license: null
text_license_url: null
text_source_url: null

<!-- body_text:start -->
    2.1.4 Incorrect implementation of ERC-4626 maximum limit functions

    Severity       Low
    Status       Partially Fixed in Version 2
    Introduced by        Version 1
    Description In the contract AsyncVault, ERC-4626 maximum limit functions are implemented
    incorrectly. Specifically, functions maxDeposit() and maxMint() do not reflect the maxSupply
    constraint, and the function maxWithdraw() does not account for fees. Additionally, none of the
    max functions return 0 when the vault is paused, as required by the ERC-4626 specification 1 .
    As a result, integrators may receive incorrect capacity signals, leading to failed transactions
    and inconsistent ERC-4626 behavior.
    617      function maxWithdraw(address owner) public view returns (uint256) {
    618          (uint256 sharesCanRequestRedeem, ) = _getFirstEligibleShares(owner, uint64(block.timestamp)
                     );
    619          return _convertToAssets(sharesCanRequestRedeem, Math.Rounding.Floor);
    620      }

                              Listing 2.4: src/r25-pc/AsyncVault/AsyncVault.sol

    596      function maxDeposit(address) public view returns (uint256) {
    597          return maxDepositLimit;
    598      }

    600      /**
    601       * @notice Returns the maximum amount of shares that can be minted by a given address
    602       * @dev Calculated from maxDeposit limit

    https://eips.ethereum.org/EIPS/eip-4626

    603       * @return The maximum mint amount in share units
    604       */
    605      function maxMint(address) public view returns (uint256) {
    606          return _convertToShares(maxDepositLimit, Math.Rounding.Floor);
    607      }

                             Listing 2.5: src/r25-pc/AsyncVault/AsyncVault.sol

    Impact This may cause failed transactions due to incorrect capacity signals returned by these
    functions.
    Suggestion      Align these functions with the specification of EIP4626.
    Feedback from the project The project clarified that they temporarily do not consider the
    pause situation and will upgrade the implementation in the future.


<!-- body_text:end -->

## "Lack of check on assetsAfterFee in function batchRedeem()"

finding_uid: "finding:b4d338d088e5902eeb5f1d6d3be9b4c24995449194aa69dd6752b83b872c5030"
finding_id: "2.1.2"
title: "Lack of check on assetsAfterFee in function batchRedeem()"
severity: "low"
status: "acknowledged"
vuln_group: "input_validation"
vuln_leaf: "input_validation.bounds"
engagement_id: "engagement:39b4acb9aad8ba75495d38d2e0926e0f630e3550b3f9f40713ed7e5614f91f20"
body_text_status: "present"
text_withheld: null
body_truncated: false
body_text_redactions: "{}"
text_attribution: null
text_license: null
text_license_url: null
text_source_url: null

<!-- body_text:start -->
2.1.2 Lack of check on assetsAfterFee in function batchRedeem()

Severity      Low
Status       Confirmed

Introduced by    Version 1
Description In the contract AsyncVault, the function batchRedeem() converts redeemed shares
into assets and applies a withdrawal fee. Under certain conditions, e.g., a very small share
amount, a low settlementNav, assetsAfterFee may become zero. If swaper.withdrawByAgent()
reverts when the withdraw value is zero, the function will revert, blocking normal settlement
for all requests in that batch. Furthermore, retrying the affected request individually will also
revert, as the settlement amount for that unlock time remains zero, leaving the request perma-
nently stuck. Conversely, if the swaper accepts such withdrawals, the shares are burned while
the user receives no assets.
1247         uint256 assets = request.shares.mulDiv(settlementNav, NAV_PRECISION, Math.Rounding.
                  Floor);
1248         uint256 fee = assets.mulDiv(
1249             withdrawFeeBps,
1250             FEE_PRECISION,
1251             Math.Rounding.Ceil
1252         );

1254         uint256 assetsAfterFee = assets - fee;

1256         _transferByUnlockTime(address(this), address(0), request.shares, request.unlockTime);
1257         uint256 withdrawalId = withdrawQueue.requestWithdrawal(
1258             assetsAfterFee,
1259             request.receiver,
1260             request.owner,
1261             requestId
1262         );

1264         totalFeesCollected += fee;
1265         _unlockTimeToRequestIds[request.unlockTime].remove(requestId);
1266         _ownerToRequestIds[request.owner].remove(requestId);
1267         delete redeemRequests[requestId];

1269         // Withdraw the underlying tokens from swaper
1270         swaper.withdrawByAgent(requestId, custodian, assetsAfterFee);

                      Listing 2.2: src/r25-pc/AsyncVault/AsyncVault.sol

Impact A redemption request may become permanently stuck, or a user may lose shares
while receiving zero assets.
Suggestion Add a check to ensure that assetsAfterFee is greater than 0, and add corre-
sponding processing logic.
Feedback from the project The project indicated that the withdrawal fee would not be en-
abled in practice, and settlementNav would always be greater than NAV_PRECISION. Therefore,
the edge case would not ocurr.


<!-- body_text:end -->

## "Potential gas griefing in function batchAutoRenew()"

finding_uid: "finding:b8d1e52bca6efcec402468618347711dbd270440b36ea48d72180924762efba4"
finding_id: "2.1.3"
title: "Potential gas griefing in function batchAutoRenew()"
severity: "low"
status: "acknowledged"
vuln_group: "dos"
vuln_leaf: "dos.resource_limits"
engagement_id: "engagement:39b4acb9aad8ba75495d38d2e0926e0f630e3550b3f9f40713ed7e5614f91f20"
body_text_status: "present"
text_withheld: null
body_truncated: false
body_text_redactions: "{}"
text_attribution: null
text_license: null
text_license_url: null
text_source_url: null

<!-- body_text:start -->
2.1.3 Potential gas griefing in function batchAutoRenew()

Severity   Low

Status     Confirmed
Introduced by      Version 1
Description In the contract AsyncVault, the function batchAutoRenew() processes shares un-
der a given oldUnlockTime that have not entered a redeem request and automatically rolls
these shares into a new unlock time. The function iterates through the address set in the
variable _unlockTimeToUserAddress[oldUnlockTime]. Therefore, the gas cost of the function
is related to the number of holders. However, the lack of restrictions on holder count exposes
the function to gas griefing. Specifically, the transfer does not enforce a minimum trans-
fer amount, nor does it have a whitelist restriction. This allows an attacker to distribute tiny
amounts of shares with the same unlock time across many addresses. As a result, the variable
_unlockTimeToUserAddress[oldUnlockTime] can become significantly larger, leading to higher
gas consumption required by the function batchAutoRenew().
864      function batchAutoRenew(
865          uint64 oldUnlockTime,
866          uint256 batchSize
867      ) external onlyRole(BizRole.CONTROLLER) returns (uint16 processedCount) {
868          if (batchSize == 0) {
869              batchSize = DEFAULT_BATCH_SIZE;
870          }

872         if (batchSize > MAX_REQUEST_BATCH) {
873             revert BatchSizeTooLarge(batchSize);
874         }

876         if (block.timestamp < oldUnlockTime - redeemNoticePeriod) {
877             revert InvalidRenewTimestamp(oldUnlockTime);
878         }

880         EnumerableSet.AddressSet storage users = _unlockTimeToUserAddress[oldUnlockTime];

882         uint16 userCount = type(uint16).max;
883         if (EnumerableSet.length(users) < userCount) {
884             userCount = uint16(EnumerableSet.length(users));
885         }

887         // Calculate how many users to process
888         uint256 toProcess = batchSize;
889         if (batchSize > userCount) {
890             toProcess = userCount;
891         }

893         address[] memory userList = new address[](toProcess);
894         for (uint256 i = 0; i < toProcess; i++) {
895             userList[i] = users.at(i);
896         }

898         // Process each user
899         for (uint256 i = 0; i < toProcess; i++) {
900             // Skip self
901             address owner = userList[i];

    902               if (owner == address(this)) {
    903                   continue;
    904               }

    906               uint256 shares = _sharesLocks[owner][oldUnlockTime];
    907               if (shares > 0) {
    908                   _autoRenew(owner, oldUnlockTime, shares);
    909                   processedCount++;
    910               }
    911           }

    913           emit BatchAutoRenewProcessed(oldUnlockTime, processedCount);
    914           return processedCount;
    915      }

                              Listing 2.3: src/r25-pc/AsyncVault/AsyncVault.sol

    Impact       This vulnerability may increase the gas cost of the function batchAutoRenew().
    Suggestion        Revise the code logic accordingly.
    Feedback from the project          The project confirmed that the impact was acceptable.


<!-- body_text:end -->

## "Lack of check on maturityPeriod"

finding_uid: "finding:e25a97734adaeaa4e0052cdc3a4652f5832c36f94c5ba8036f757e5726dbf75a"
finding_id: "2.1.6"
title: "Lack of check on maturityPeriod"
severity: "low"
status: "fixed"
vuln_group: "input_validation"
vuln_leaf: "input_validation.bounds"
engagement_id: "engagement:39b4acb9aad8ba75495d38d2e0926e0f630e3550b3f9f40713ed7e5614f91f20"
body_text_status: "present"
text_withheld: null
body_truncated: true
body_text_redactions: "{}"
text_attribution: null
text_license: null
text_license_url: null
text_source_url: null

<!-- body_text:start -->
2.1.6 Lack of check on maturityPeriod

Severity      Low
Status       Fixed in Version 2
Introduced by       Version 1
Description In the contract AsyncVault, the function batchRedeem() uses the NAV at the set-
tlement time (i.e., request.unlockTime - 1 days) to process matured redeem requests. If the
NAV value is zero, the function reverts. Meanwhile, the function handleOracleReport() only
allows the Oracle to report NAV at strict 1-day intervals. This means that the settlement time
needs to be an integer multiple of 1 day. The settlement time is derived from lastAccountingTime-
stamp + maturityPeriod + 1 day for a new issuance, and from oldUnlockTime + maturityPeriod
for a renewal.
     However, the function initialize() only checks that maturityPeriod is non-zero, and
maturityPeriod cannot be modified once initialized. If maturityPeriod is not a multiple of 1
days, the settlement time will not align to a day boundary, causing the redemption invocation
to fail permanently.
 512     function initialize(IAsyncVault.InitializeParams calldata params) public initializer {
 513         if (
 514             params.admin == address(0) ||

 515            params.asset == address(0) ||
 516            params.withdrawQueue == address(0) ||
 517            params.whitelist == address(0) ||
 518            params.swaper == address(0) ||
 519            params.maturityPeriod == 0 ||
 520            IERC20Metadata(params.asset).decimals() != 6
 521      ) {
 522            revert InvalidInput();
 523      }

                        Listing 2.8: src/r25-pc/AsyncVault/AsyncVault.sol

1496   function handleOracleReport(
1497       ReportData calldata report
1498   ) external onlyRole(BizRole.ORACLE_REPORTER_ROLE) {
1499       // Sequence validation
1500       if (accounting.lastAccountingTimestamp != 0 && accounting.lastReportId != 0) {
1501           if (
1502               (report.accountingTimestamp - accounting.lastAccountingTimestamp != 1 days) ||
1503               (report.reportId - accounting.lastReportId != 1)
1504           ) {
1505               revert InvalidReport(
1506                   report.reportId,
1507                   report.accountingTimestamp,
1508                   report.todayNav
1509               );
1510           }
1511       }

1513      if (block.timestamp < report.accountingTimestamp) {
1514          revert InvalidReport(
1515              report.reportId,
1516              report.accountingTimestamp,
1517              report.todayNav
1518          );
1519      }

1521      // Fluctuation validation: based on latestNav vs report.todayNav
1522      if (accounting.latestNav > 0 && totalSupply() > 0) {
1523          uint256 navDifference = report.todayNav > accounting.latestNav
1524              ? report.todayNav - accounting.latestNav
1525              : accounting.latestNav - report.todayNav;

1527            uint256 fluctuationBps = navDifference.mulDiv(
1528                FEE_PRECISION,
1529                accounting.latestNav,
1530                Math.Rounding.Floor
1531            );

1533            if (fluctuationBps > maxFluctuationBps) {
1534                revert InvalidReport(
1535                    report.reportId,
1536                    report.accountingTimestamp,

1537                     report.todayNav
1538                );
1539            }
1540        }

1542        // Record historical NAV
1543        dailyNav[report.accountingTimestamp] = report.todayNav;
1544        uint256 preNav = accounting.latestNav;

                          Listing 2.9: src/r25-pc/AsyncVault/AsyncVault.sol

1241            uint64 settlementTime = request.unlockTime - 1 days;
1242            uint256 settlementNav = dailyNav[settlementTime];
1243            if (settlementNav == 0) {
1244               revert NavNotUpdate(settlementTime);
1245            }

                         Listing 2.10: src/r25-pc/AsyncVault/AsyncVault.sol

1995        if (from == address(0) && to != address(0)) {
1996            // deposit/mint or other mint scenarios
1997            if (accounting.lastAccountingTimestamp == 0) {
1998                revert AccountingNotSet();
1999            }
2000            uint64 unlockTime = SafeCast.toUint64(
2001                accounting.lastAccountingTimestamp + maturityPeriod + 1 days
2002            );

                         Listing 2.11: src/r25-pc/AsyncVault/AsyncVault.sol

 918     function _autoRenew(
 919         address owner,
 920         uint64 oldUnlockTime,
 921         uint256 shares
 922     ) internal {
 923         uint64 newUnlockTime = SafeCast.toUint64(oldUnlockTime + maturityPeriod);

 925        _removeShare(owner, oldUnlockTime);
 926        _onReceiveShares(owner, shares, newUnlockTime, 0);

                         Listing 2.12: src/r25-pc/AsyncVault/AsyncVault.sol

Impact     This vulnerability may lead to the unavailability of redemption functionality.
Suggestion      Validate that maturityPeriod is a non-zero multiple of 1 days during initialization.


2.2 Recommendation

2.2.1 Add an upper-bound check in setMaxFluctuationBps()

Status     Confirmed
Introduced by       Version 1

Description In contract AsyncVault, functions setMaxSupply(), setMaxDepositLimit(), and
setMaxFluctuationBps() lack boundary validation on crucial configurations.
     Specifically, functions setMaxSupply() and setMaxDepositLimit() permit a value of zero,
which would cause every subsequent deposit() and mint() invocation to revert immediately.
Function setMaxFluctuationBps() has no lower or upper bound. Setting it to zero causes every
oracle report to be rejected as the computed fluctuationBps will always exceed the limit, per-
manently blocking NAV updates. Setting it above FEE_PRECISION renders the fluctuation check
trivially satisfiable, negating its intended protection against abrupt NAV manipulation.
1669     function setMaxSupply(
1670         uint256 maxSupply_
1671     ) external onlyRole(BizRole.CONTROLLER) {
1672         uint256 preMaxSupply = maxSupply;
1673         maxSupply = maxSupply_;
1674         emit ConfigUpdated(preMaxSupply, maxSupply_, ConfigType.MAX_SUPPLY);
1675     }

                        Listing 2.13: src/r25-pc/AsyncVault/AsyncVault.sol

1684     function setMaxDepositLimit(
1685         uint256 maxDepositLimit_
1686     ) external onlyRole(BizRole.CONTROLLER) {
1687         uint256 preMaxDepositLimit = maxDepositLimit;
1688         maxDepositLimit = maxDepositLimit_;
1689         emit ConfigUpdated(
1690             preMaxDepositLimit,
1691             maxDepositLimit_,
1692             ConfigType.MAX_DEPOSIT_LIMIT
1693         );
1694     }

                        Listing 2.14: src/r25-pc/AsyncVault/AsyncVault.sol

1703     function setMaxFluctuationBps(
1704         uint256 maxFluctuationBps_
1705     ) external onlyRole(BizRole.CONTROLLER) {
1706         uint256 preMaxFluctuationBps = maxFluctuationBps;
1707         maxFluctuationBps = maxFluctuationBps_;
1708         emit ConfigUpdated(
1709             preMaxFluctuationBps,
1710             maxFluctuationBps_,
1711             ConfigType.MAX_FLUCTUATION_BPS
1712         );
1713     }

                        Listing 2.15: src/r25-pc/AsyncVault/AsyncVault.sol

Suggestion      Enforce clear boundary checks for the functions.

2.2.2 Fix storage gap size

Status     Confirmed

Introduced by       Version 1
Description The contract AsyncVault declares a storage gap to reserve space for future up-
grades. However, since the contract declares some state variables. Therefore, the size of
__gap should not be 50 considering OpenZeppelin’s convention.
2250     /// forge-lint: disable-next-line(mixed-case-variable)
2251     uint256[50] private __gap;

                         Listing 2.16: src/r25-pc/AsyncVault/AsyncVault.sol

Suggestion        Recalculate and adjust the __gap length to conform to the standard 50-slot lay-
out.

2.2.3 Add input validation in function createAsyncVault()

Status       Confirmed
Introduced by       Version 1
Description In the contract AsyncVaultFactory, function createAsyncVault() is expected to
enforce meaningful identity parameters for registry keys and ERC-20 metadata. However, it
forwards tokenName and tokenSymbol without checks and derives the registry key from keccak256(
abi.encodePacked(organization, tokenName)) even when organization is zero and the strings
are empty. This lack of validation allows a vault with empty metadata and a zero-organization
namespace to be deployed.
 109     function createAsyncVault(
 110         InitVaultParam calldata initVaultParam
 111     ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
 112         // Validation and preparation
 113         bytes32 tokenNameHashed = _prepareDeployment(initVaultParam);

 115          // Deploy all contracts
 116          DeployedContracts memory deployed = _deployContracts(initVaultParam, tokenNameHashed);

 118          // Register and emit events
 119          _finalizeDeployment(initVaultParam, tokenNameHashed, deployed);

 121          return deployed.vaultProxy;
 122     }

 124     function _prepareDeployment(
 125         InitVaultParam calldata initVaultParam
 126     ) internal view returns (bytes32 tokenNameHashed) {
 127         tokenNameHashed = keccak256(abi.encodePacked(
 128             initVaultParam.organization,
 129             initVaultParam.tokenName
 130         ));

                     Listing 2.17: src/r25-pc/AsyncVault/AsyncVaultFactory.sol

Suggestion Reject empty tokenName, empty tokenSymbol, and organization == bytes32(0)
before deployment.

2.2.4 Emit events before deleting request data

Status   Fixed in Version 2
Introduced by   Version 1
Description In the function batchRedeem(), request is a storage reference to redeemRequests-
[requestId]. Once redeemRequests[requestId] is deleted from storage, subsequent reads
through request return default zero values. As a result, events CustomWithdraw and Withdraw
emitted afterward may contain incorrect fields (e.g., request.shares). This creates an incon-
sistency between the actual withdrawal execution and the event data.
1230         RedeemRequestDetail storage request = redeemRequests[requestId];

                     Listing 2.18: src/r25-pc/AsyncVault/AsyncVault.sol

1267         delete redeemRequests[requestId];

1269         // Withdraw the underlying tokens from swaper
1270         swaper.withdrawByAgent(requestId, custodian, assetsAfterFee);

1272         emit CustomWithdraw(
1273             msg.sender,
1274             request.receiver,
1275             request.owner,
1276             assetsAfterFee,
1277             request.shares,
1278             fee,
1279             requestId,
1280             withdrawalId
1281         );

1283         emit Withdraw(
1284             msg.sender,
1285             request.receiver,
1286             request.owner,
1287             assetsAfterFee,
1288             request.shares
1289         );

                     Listing 2.19: src/r25-pc/AsyncVault/AsyncVault.sol

Suggestion    Emit the events before the delete operation.

2.2.5 Revise the incorrect parameters

Status   Confirmed
Introduced by   Version 1
Description 1. In the interface IERC7540, event RedeemRequest declares the last parameter as
assets. However, the actual value passed is shares in the contract AsyncVault. According to the
ERC-7540 specification, this parameter semantically represents shares, creating a mismatch
between the ABI label and the on-chain data.

    2. In contract AsyncVault, the error ExceededMaxSupply defines its second parameter as
assets, while the functions deposit() and mint() actually pass shares.
 102     event RedeemRequest(
 103         address indexed controller, address indexed owner, uint256 indexed requestId, address
                 sender, uint256 assets
 104     );

                          Listing 2.20: src/r25-pc/interface/IERC7540.sol

1186        emit RedeemRequest(controller, owner, requestId, msg.sender, shares);

                        Listing 2.21: src/r25-pc/AsyncVault/AsyncVault.sol

 227     error ExceededMaxSupply(
 228         address receiver,
 229         uint256 assets,
 230         uint256 maxSupply
 231     );

                        Listing 2.22: src/r25-pc/AsyncVault/AsyncVault.sol

Suggestion      Rename the error parameter from assets to shares.

2.2.6 Use different boundary conditions for cancellation and renewal

Status     Confirmed
Introduced by      Version 1
Description In the contract AsyncVault, functions batchAutoRenew(), renewByUsers(), request-
Redeem(), and cancelRedeemRequest() are callable at the exact same boundary timestamp of
unlockTime - redeemNoticePeriod. As a result, both the request, cancellation, and renewal
operations are valid simultaneously at the exact boundary point.
1196     function _getFirstEligibleShares(
1197         address owner,
1198         uint64 currentTime
1199     ) internal view returns (uint256 shares, uint64 timestamp) {
1200         uint64 unlockTime = _nextTimelock[owner][GUARD];
1201         while (unlockTime != GUARD) {
1202             if (unlockTime > currentTime && unlockTime - currentTime >= redeemNoticePeriod) {
1203                 shares = _sharesLocks[owner][unlockTime];
1204                 timestamp = unlockTime;
1205                 break;
1206             }
1207             unlockTime = _nextTimelock[owner][unlockTime];
1208         }
1209     }

                        Listing 2.23: src/r25-pc/AsyncVault/AsyncVault.sol

1325     function _validateAndCancelRequest(
1326         uint256 requestId

1327     ) internal returns (address owner, uint256 shares, uint64 unlockTime) {
1328         // 1. Get request from storage
1329         RedeemRequestDetail storage request = redeemRequests[requestId];

1331        // 2. Check if there are pending shares (validates request exists)
1332        if (request.shares == 0) {
1333            revert InvalidInput();
1334        }

1336        // 3. Validate caller is the request owner
1337        if (msg.sender != request.owner) {
1338            revert NotAuthorized();
1339        }

1341        // 4. Validate advance notice period
1342        uint64 currentTime = SafeCast.toUint64(block.timestamp);
1343        if (request.unlockTime <= currentTime || request.unlockTime - currentTime <
                 redeemNoticePeriod) {
1344            revert OperationTooLate(
1345                request.owner,
1346                request.unlockTime,
1347                currentTime,
1348                redeemNoticePeriod
1349            );
1350        }

                        Listing 2.24: src/r25-pc/AsyncVault/AsyncVault.sol

 864     function batchAutoRenew(
 865         uint64 oldUnlockTime,
 866         uint256 batchSize
 867     ) external onlyRole(BizRole.CONTROLLER) returns (uint16 processedCount) {
 868         if (batchSize == 0) {
 869             batchSize = DEFAULT_BATCH_SIZE;
 870         }

 872        if (bat
[truncated; see the linked report]
<!-- body_text:end -->

## "Potential gas griefing attacks"

finding_uid: "finding:f699144024114c0ed26fd33f3ccc50760cfb1df5e752ff25ebd947ebc1a90597"
finding_id: "2.1.1"
title: "Potential gas griefing attacks"
severity: "low"
status: "acknowledged"
vuln_group: "dos"
vuln_leaf: "dos.unbounded_work"
engagement_id: "engagement:39b4acb9aad8ba75495d38d2e0926e0f630e3550b3f9f40713ed7e5614f91f20"
body_text_status: "present"
text_withheld: null
body_truncated: false
body_text_redactions: "{}"
text_attribution: null
text_license: null
text_license_url: null
text_source_url: null

<!-- body_text:start -->
2.1.1 Potential gas griefing attacks

Severity      Low
Status       Confirmed
Introduced by       Version 1
Description The contract AsyncVault stores each user’s time-locked share positions as an
ordered linked list and linearly traverses these batches across multiple execution paths. As the
number of batches grows, the gas cost of these operations increases. However, there is no
upper bound on the number of timelock batches. This allows an attacker to repeatedly transfer
shares on N distinct days to inject nodes into a benign user’s list. This griefing attack gradually
increases the victim’s list size and makes subsequent related query paths increasingly gas-
expensive.
1827     function getAvailableShares(
1828         address owner,
1829         uint64 currentTime
1830     ) public view returns (uint256 availableShares) {
1831         uint64 unlockTime = _nextTimelock[owner][GUARD];
1832         while (unlockTime != GUARD && unlockTime <= currentTime) {
1833             availableShares += _sharesLocks[owner][unlockTime];
1834             unlockTime = _nextTimelock[owner][unlockTime];
1835         }
1836     }

                         Listing 2.1: src/r25-pc/AsyncVault/AsyncVault.sol

Impact The attacker could intentionally increase the gas costs of a benign user’s related
query paths over time.
Suggestion       Revise the logic accordingly.
Feedback from the project The project considered this risk acceptable, as a user is expected
to hold only one share record per day. Exploiting this issue would require the attacker to transfer
shares to the victim continuously over a long period.


<!-- body_text:end -->

