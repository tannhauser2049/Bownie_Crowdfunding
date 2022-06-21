from brownie import Crowdfunding, MockV3Aggregator, network, config
from scripts.helpful_scripts import get_account, deploy_mocks, LOCAL_BLOCKCHAIN_ENV


def deploy_crowdfunding():
    account = get_account()
    # pass the price feed address to crowdfunding contract
    # if we are on a persistent testnet like rinkeby, use the associated address
    # otherwise, deploy mocks
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENV:
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
    else:
        deploy_mocks()
        price_feed_address = MockV3Aggregator[-1].address

    crowd_funding = Crowdfunding.deploy(
        price_feed_address,
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify"),
    )
    print(f"Contract deployed to {crowd_funding.address}")
    return crowd_funding


def main():
    deploy_crowdfunding()
