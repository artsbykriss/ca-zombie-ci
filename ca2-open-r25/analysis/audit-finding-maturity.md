---
{
  "audit_date_basis": "report_issue",
  "audit_date_max": "2026-04-28",
  "audit_date_min": "2026-04-28",
  "audit_type": "protocol",
  "audit_year": 2026,
  "body_available": true,
  "body_text_redactions": "{}",
  "body_text_status": "present",
  "body_truncated": true,
  "chains": [
    "unknown"
  ],
  "engagement_id": "engagement:39b4acb9aad8ba75495d38d2e0926e0f630e3550b3f9f40713ed7e5614f91f20",
  "extraction_variant": "blocksec/v2025_version_fields",
  "finding_id": "2.1.6",
  "finding_phase": "initial_audit",
  "finding_uid": "finding:e25a97734adaeaa4e0052cdc3a4652f5832c36f94c5ba8036f757e5726dbf75a",
  "firm": "BlockSec",
  "firm_id": "blocksec",
  "languages": [
    "unknown"
  ],
  "ordinal": 6,
  "original_url": "https://github.com/blocksecteam/audit-reports/blob/9da368848d5a3b2a4e0f76a4e6dd04091de5d623/solidity/blocksec_r25_asyncvault_contracts_signed_20260428.pdf",
  "page_end": 15,
  "page_start": 13,
  "project": "R25",
  "project_node_id": "project-label:dd969507b8d0f86dbf1bbb187e6f8babe336998c40648fb0e60d75ffc694e095",
  "report_id": "2632908bf2bf46f83d212b778870d417c03040a9ba6556ee1583cc8b619ad225",
  "report_path": "reports/blocksec/2026/r25-2632908b.md",
  "schema_version": "web3-agent-files-v1",
  "selected_for_stats": true,
  "severity": "low",
  "severity_original": "Low",
  "source": "phase4",
  "source_release": "v1.3.0",
  "status": "fixed",
  "status_original": "Fixed",
  "text_attribution": null,
  "text_license": null,
  "text_license_url": null,
  "text_source_url": null,
  "text_withheld": null,
  "title": "Lack of check on maturityPeriod",
  "vuln_confidence": 0.99,
  "vuln_group": "input_validation",
  "vuln_leaf": "input_validation.bounds",
  "vuln_needs_review": false
}
---

# Lack of check on maturityPeriod

Source: [Original report](<https://github.com/blocksecteam/audit-reports/blob/9da368848d5a3b2a4e0f76a4e6dd04091de5d623/solidity/blocksec_r25_asyncvault_contracts_signed_20260428.pdf>)

Context: [Report extract](../../../../reports/blocksec/2026/r25-2632908b.md)

Browse: [BlockSec](../../../../hubs/firms/blocksec/README.md) | [R25](../../../../hubs/projects/dd/r25--dd969507b8d0f86dbf1bbb187e6f8babe336998c40648fb0e60d75ffc694e095/README.md) | [unknown](../../../../hubs/languages/unknown/README.md) | [unknown](../../../../hubs/chains/unknown/README.md) | [input_validation](../../../../hubs/classes/input-validation/README.md) | [input_validation.bounds](../../../../hubs/classes/input-validation/bounds/README.md)

Release note: body_truncated=true; the released excerpt is incomplete.

## Released finding text

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
