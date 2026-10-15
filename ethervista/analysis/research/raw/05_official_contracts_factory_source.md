# Raw: official contract list + factory source (decisive for key custody)

## GitHub Ethervista/Deployed-Contracts README (verbatim; last commit 2024-10-24)
URL: https://github.com/Ethervista/Deployed-Contracts (fetched 2026-10-15)
ROUTER: 0xCEDd366065A146a039B92Db35756ecD7688FCC77
FACTORY: 0x9a27cb5ae0B2cEe0bb71f9A85C0D60f3920757B4
SAFE_TOKEN_FACTORY: 0x1a97A037A120Db530dDCe8370e24EaD0FE9cf5d0
HARDLOCK (all tokens): 0xF6B510928ab880507246CD6946b7F061Eb8A9C78
HARDSTAKE/BOOST: 0xEE5a6F8a55B02689138c195031d09BAFDc7d278F
HARDLOCK (vista_lp only): 0x9099EF7f34dC1af0d27e49Dc5B604bcCC03dCB21
VISTA-ERC20: 0xC9bCa88B04581699fAb5aa276CCafF7Df957cbbf
VISTA-PAIR: 0xfdd05552F1377aA488AFed744c8024358AF02041
AUTOBUY-BURNER: 0xe17A0C382c8332A889EC9D026D6948e26C7f617D

## factory.sol key excerpts (verbatim)
RAW: https://raw.githubusercontent.com/Ethervista/Deployed-Contracts/main/factory.sol
```solidity
pragma solidity =0.5.16;
contract EtherVistaFactory is IEtherVistaFactory {
    address public feeTo;
    address public feeToSetter;
    address public routerSetter; 
    address public router; 
    ...
    constructor() public {
        feeToSetter = 0x0000000000000000000000000000000000000000;
        routerSetter = msg.sender;
    }
    function setRouter(address _router) external {
        require(msg.sender == routerSetter, 'EtherVista: FORBIDDEN');
        router = _router;
    }
    //Can be set to the zero-address if there is no intent to upgrade Router versions
    function setRouterSetter(address setter) external {
        require(msg.sender == routerSetter, 'EtherVista: FORBIDDEN');        
        routerSetter = setter;
    }
    ...
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'EtherVista: FORBIDDEN');
        feeTo = _feeTo;
    }
```
Implications: single-address router authority (set to msg.sender at deploy); no multisig/timelock/2-step; feeToSetter burned to 0x0 at deployment (feeTo can never be changed).

## ethervista.sol (VISTA token in same repo) — approve() restriction excerpt
```solidity
function approve(address spender, uint256 value) public virtual returns (bool) {
    require(spender == IEtherVistaFactory(factory).router(), 'EtherVista: FORBIDDEN');
    ...
}
```

## Etherscan label facts (fetched 2026-10-15/16)
- 0xCA90D843288E35beeADfCe14E5F906e3F1AFc7cB = "Ethervista: Deployer" (no contract code; token dust only). ContractCreator of VISTA token and of router 0xcedd36.
- 0xcedd366065a146a039b92db35756ecd7688fcc77 = "Ethervista: Router", verified, creator "Ethervista: Deployer" (~2024-09-29), 53,726 txns, balance ~$6.7.
- 0x9bd63c5d44ff28390df1eaafd4eb4bd73e94a72a = verified contract "EtherVistaRouter" (no public label). ethscanner: 1,255 txns as of 2026-09-06. Bloxy: createPair calls via factory as of 2026-05-25.
- 0x9a27cb5ae0B2cEe0bb71f9A85C0D60f3920757B4 = verified "EtherVistaFactory".
- VISTA token 0xc9bca88b04581699fab5aa276ccaff7df957cbbf = "Ethervista: VISTA Token".
