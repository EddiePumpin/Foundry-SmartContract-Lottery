// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Raffle} from "../../src/Raffle.sol";

contract IntegrationTest is Test {
    HelperConfig public helperConfig;
    Raffle public raffle;
    CreateSubscription public createSubscription;
    FundSubscription public fundSubscription;
    AddConsumer public addConsumer;
    address vrfCoordinatorV2_5;
    address account;
    uint256 subscriptionId;
    address link;

    function setUp() external {
        helperConfig = new HelperConfig();
        createSubscription = new CreateSubscription();
        fundSubscription = new FundSubscription();
        addConsumer = new AddConsumer();

        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vrfCoordinatorV2_5 = config.vrfCoordinatorV2_5;
        account = config.account;
        subscriptionId = config.subscriptionId;
        link = config.link;

        raffle = new Raffle(
            subscriptionId,
            config.gasLane,
            config.interval,
            config.entranceFee,
            config.callbackGasLimit,
            vrfCoordinatorV2_5
        );
    }

    function testCreateSubscriptionWithoutUpdatingItInHelperConfig() public {
        (uint256 subId,) = createSubscription.createSubscription(vrfCoordinatorV2_5, account);

        assert(subId != subscriptionId);
    }

    function testFundSubscription() public {
        (uint256 subId,) = createSubscription.createSubscription(vrfCoordinatorV2_5, account);
        fundSubscription.fundSubscription(vrfCoordinatorV2_5, subId, link, account);
    }

    function testAddConsumer() public {
        (uint256 subId,) = createSubscription.createSubscription(vrfCoordinatorV2_5, account);
        fundSubscription.fundSubscription(vrfCoordinatorV2_5, subId, link, account);

        addConsumer.addConsumer(address(raffle), vrfCoordinatorV2_5, subId, account);
    }
}
