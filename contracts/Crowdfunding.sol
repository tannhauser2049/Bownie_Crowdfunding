// SPDX-License-Identifier: MIT

// This is a smart contract that lets anyone to fund it with ETH
// And it makes sure that only the owner can withdraw the balance of this contract
pragma solidity ^0.8.0;

// A data feed oracle from chainlink to convert ETH into USD
// We use v0.8 to adapt the solidity version of 0.8.0
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Crowdfunding {
    // mapping to store the fund balance of each address
    mapping(address => uint256) public BalanceOfAddress;
    address[] public funders;
    // address of the one who deployed the contract (owner)
    address public owner;
    AggregatorV3Interface public priceFeed;

    // to make sure the owner becomes the msg.sender
    // right after the contract been deployed
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        // the minimum threshold of funding amount is 50 USD in 18 digit
        uint256 minimumUSD = 50 * 10**18;
        require(
            getUsd(msg.value) >= minimumUSD,
            "Sorry, your fund amount can not be less than 50 USD"
        );
        // add the qualified address to mapping and funders array
        BalanceOfAddress[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData(); // only use the answer result among the latestrounddata function
        return uint256(answer * 10000000000); // ETH/USD rate in 18 digit because the answer gives an 8 digit result
    }

    function getUsd(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        // the actual USD amount by removing extra 0s
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        // return (minimumUSD * precision) / price;
        // We fixed a rounding error found in the video by adding one!
        return ((minimumUSD * precision) / price) + 1;
    }

    modifier ownerOnly() {
        // set a modifier to ensure that only the owner can withdraw
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable ownerOnly {
        payable(msg.sender).transfer(address(this).balance); // withdraw all the balance to owner's account

        // iterate through all the funders' address to make their balance 0
        for (
            uint256 funderList = 0;
            funderList < funders.length;
            funderList++
        ) {
            address funder = funders[funderList];
            BalanceOfAddress[funder] = 0;
        }
        // reinitialize the funders list
        funders = new address[](0);
    }
}
