// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    // Raffle public raffle;

    // HelperConfig public helperConfig;

    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig(); // ContractName.StructName. By specifying HelperConfig.NetworkConfig, you're referencing the NetworkConfig struct that is scoped within the HelperConfig contract or library.

        if (config.subscriptionId == 0) {
            // This means if we don't have a subscriptionId, the next lines will create one
            CreateSubscription createSubscription = new CreateSubscription();
            // (subId, config.vrfCoordinatorV2_5)  = createSubscription.run();
            (
                config.subscriptionId,
                config.vrfCoordinatorV2_5
            ) = createSubscription.createSubscription(
                config.vrfCoordinatorV2_5,
                config.account
            );

            FundSubscription fundSubscription = new FundSubscription();
            //fundSubscription.run();
            fundSubscription.fundSubscription(
                config.vrfCoordinatorV2_5,
                config.subscriptionId,
                config.link,
                config.account
            );
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.subscriptionId,
            config.gasLane,
            config.interval,
            config.entranceFee,
            config.callbackGasLimit,
            config.vrfCoordinatorV2_5
        );
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        // Don't need to broadcast because we have aleady done that in Interactions file.
        addConsumer.addConsumer(
            address(raffle),
            config.vrfCoordinatorV2_5,
            config.subscriptionId,
            config.account
        );

        return (raffle, helperConfig);
    }
}
