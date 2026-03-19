pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SimplePaymentChannel.sol";

contract SimplePaymentChannelTest is Test {
    SimplePaymentChannel channel;
    uint256 alicePrivKey = 0x1234;
    address alice = vm.addr(alicePrivKey);
    address bob = address(0xB0B);
    uint256 carolPrivKey = 0x5678;
    address carol = vm.addr(carolPrivKey);

    function setUp() public {
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        channel = new SimplePaymentChannel{value: 10 ether}(payable(bob), 4 days);
    }

    function testSetUp() public view {
        assertEq(channel.sender(), alice);
        assertEq(channel.recipient(), bob);
        assertEq(address(channel).balance, 10 ether);
    }

    function testClose() public {
        uint256 amount = 1 ether;
        // alice firm 1 ether for bob
        bytes memory signature = signPayment(amount, alicePrivKey);
        vm.warp(block.timestamp + 2 days);
        vm.prank(bob);
        channel.close(amount, signature);
        assertEq(bob.balance, amount);
        assertEq(alice.balance, 10 ether - amount);
    }

    function testInvalidClose() public {
        uint256 amount = 1 ether;
        bytes memory signature = signPayment(amount, alicePrivKey);
        bytes memory invalidSignature = signPayment(amount, carolPrivKey);
        vm.expectRevert();
        vm.prank(carol);
        channel.close(amount, signature);
        vm.expectRevert();
        vm.prank(bob);
        channel.close(amount + 1, signature);
        vm.expectRevert();
        vm.prank(bob);
        channel.close(amount, invalidSignature);
    }

    function testExtend() public {
        uint256 newExpiration = block.timestamp + 10 days;
        vm.prank(alice);
        channel.extend(newExpiration);
        assertEq(channel.expiration(), newExpiration);
    }

    function testClaimTimeout() public {
        vm.warp(block.timestamp + 5 days);
        vm.prank(alice);
        channel.claimTimeout();
        assertEq(alice.balance, 10 ether);
    }

    function testClaimTimeoutTooEarly() public {
        vm.warp(block.timestamp + 2 days);
        vm.expectRevert();
        vm.prank(alice);
        channel.claimTimeout();
    }









    function signPayment(uint256 amount, uint256 privKey) internal view returns (bytes memory) {
        // Recreate the same message that the contract will check: keccak256(abi.encodePacked(this, amount))
        bytes32 messageHash = keccak256(abi.encodePacked(address(channel), amount));

        // Convert it to the Ethereum signed message hash.
        bytes32 ethSignedMessageHash = toEthSignedMessageHash(messageHash);

        // Sign the final digest with the provided signatory's private key.
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, ethSignedMessageHash);

        return abi.encodePacked(r, s, v);
    }
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}