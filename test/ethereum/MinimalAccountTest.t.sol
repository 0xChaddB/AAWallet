// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;   

import {Test, console2} from "forge-std/Test.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {DeployMinimal} from "script/DeployMinimal.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp} from "script/SendPackedUserOp.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MinimalAccountTest is Test {

    using MessageHashUtils for bytes32; 

    HelperConfig helperConfig;
    MinimalAccount minimalAccount;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;

    address user = makeAddr("user");

    uint256 constant private AMOUNT = 100e18;

    function setUp() public {
        DeployMinimal deployer = new DeployMinimal();
        (helperConfig, minimalAccount) = deployer.deployMinimalAccount();
        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }
    // USDC Approval    
    // msg.sender -> minimalAccount
    // approve some amount
    // USDC Contract
    // come from the entrypoint

    function testOwnerCanExecuteCommands() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        // Act
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(dest, value, functionData);

        // Assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    function testNonOwnerCannotExecuteCommands() public {
        //Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        uint256 value = 0;
        address dest = address(usdc);
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        // Act
        vm.prank(user);   

        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPoint.selector);
        minimalAccount.execute(dest, value, functionData);   
        console2.log(usdc.balanceOf(address(minimalAccount)));
    }

    
    function testRecoverSignedOp() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        uint256 value = 0;
        address dest = address(usdc);
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        console2.log(usdc.balanceOf(address(minimalAccount)));
        bytes memory executeCallData = 
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);

        PackedUserOperation memory packedUserOp = 
            sendPackedUserOp.generateSignedUserOperation(executeCallData, helperConfig.getConfig(), address(minimalAccount));
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);


        // Act
        address actualSigner = ECDSA.recover(userOperationHash.toEthSignedMessageHash(), packedUserOp.signature);

        // Assert
        assertEq(actualSigner,minimalAccount.owner());
    }

    // 1. Sign user ops
    // 2. Call validate userops
    // 3. Assert the return is correct
    function testValidationOfUserOps() public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCallData =
            abi.encodeWithSelector(MinimalAccount.execute.selector, dest, value, functionData);
        PackedUserOperation memory packedUserOp = 
            sendPackedUserOp.generateSignedUserOperation(executeCallData, helperConfig.getConfig(), address(minimalAccount)
        );
        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18;
        console2.log(usdc.balanceOf(address(minimalAccount)));
        // Act
        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);
        assertEq(validationData, 0);
    }
                              
    function testEntryPointCanExecuteCommands() public {

    }
}