// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {VaultUpgradeable} from "../src/VaultUpgradeable.sol";
import {TokenRupiah} from "../src/TokenRupiah.sol";
import {
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC1967Utils} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {ProxyAdmin} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {VaultUpgradeableV2} from "../src/VaultUpgradeableV2.sol";

contract VaultUpgradeableTest is Test {
    VaultUpgradeable public vault;
    TokenRupiah public tokenRupiah;
    ProxyAdmin public proxyAdmin;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public carol = makeAddr("carol");
    address public david = makeAddr("david");

    function setUp() public {
        // deploy token
        tokenRupiah = new TokenRupiah();

        address implementation = address(new VaultUpgradeable());

        address proxy = address(
            new TransparentUpgradeableProxy(
                implementation,
                address(this),
                abi.encodeWithSelector(VaultUpgradeable.initialize.selector, address(tokenRupiah))
            )
        );

        vault = VaultUpgradeable(proxy);

        address admin = getAdminAddress(address(proxy));
        proxyAdmin = ProxyAdmin(admin);
    }

    function test_upgrade() public {
        console.log("version", vault.version());

        address implementationV2 = address(new VaultUpgradeableV2());

        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(vault)),
            implementationV2,
            abi.encodeWithSelector(VaultUpgradeableV2.initializeV2.selector)
        );

        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(vault)),
            implementationV2,
            abi.encodeWithSelector(VaultUpgradeableV2.initializeV2.selector)
        );

        console.log("version", vault.version());
    }

    function getAdminAddress(address proxy) internal view returns (address) {
        address CHEATCODE_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
        Vm vm = Vm(CHEATCODE_ADDRESS);

        bytes32 adminSlot = vm.load(proxy, ERC1967Utils.ADMIN_SLOT);
        return address(uint160(uint256(adminSlot)));
    }
}
