// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {CodeConstants} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        // HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        // address vrfCoordinatorV2_5 = config.vrfCoordinatorV2_5;
        // address account = config.account;
        address vrfCoordinatorV2_5 = helperConfig
            .getConfig()
            .vrfCoordinatorV2_5; // This will return the vrfCoordinator
        address account = helperConfig.getConfig().account;
        (uint256 subId, ) = createSubscription(vrfCoordinatorV2_5, account);
        return (subId, vrfCoordinatorV2_5);
    }

    function createSubscription(
        address vrfCoordinatorV2_5,
        address account
    ) public returns (uint256, address) {
        console.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5)
            .createSubscription(); //By using VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5), you are telling Solidity to treat that address as an instance of VRFCoordinatorV2_5Mock.
        vm.stopBroadcast();
        console.log("Your subcription Id is: ", subId);
        console.log(
            "Please update the subscription Id in your HelperConfig.s.sol"
        );
        return (subId, vrfCoordinatorV2_5);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint96 public constant FUND_AMOUNT = 3 ether; // 3 LINK

    function fundSubcriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        // CreateSubscription createSubscription = new CreateSubscription();
        address vrfCoordinatorV2_5 = helperConfig
            .getConfig()
            .vrfCoordinatorV2_5;
        //
        uint256 subId = helperConfig.getConfig().subscriptionId;
        //uint256 subId = createSubscription.createSubscription;
        address link = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;

        fundSubscription(vrfCoordinatorV2_5, subId, link, account);
    }

    function fundSubscription(
        address vrfCoordinatorV2_5,
        uint256 subId,
        address link,
        address account
    ) public {
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCoordinatorV2_5);
        console.log("On ChainId: ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(
                subId,
                FUND_AMOUNT * 100
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(link).transferAndCall(
                vrfCoordinatorV2_5,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubcriptionUsingConfig();
    }
}

contract AddConsumer is Script {
    function AddConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        address account = helperConfig.getConfig().account;
        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, account);
    }

    function addConsumer(
        address contractToAddtoVrf,
        address vrfCoordinatorV2_5,
        uint256 subId,
        address account
    ) public {
        console.log("Adding consumer contract: ", contractToAddtoVrf);
        console.log("To vrfCoordinator: ", vrfCoordinatorV2_5);
        console.log("On ChainId: ", block.chainid);

        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).addConsumer(
            subId,
            contractToAddtoVrf
        );
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        AddConsumerUsingConfig(mostRecentlyDeployed);
    }
}
