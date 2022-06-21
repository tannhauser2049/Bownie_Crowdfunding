from scripts.helpful_scripts import get_account, LOCAL_BLOCKCHAIN_ENV
from scripts.deploy import deploy_crowdfunding
from brownie import network, accounts, exceptions
import pytest


def test_can_fund_withdraw():
    account = get_account()
    crowd_funding = deploy_crowdfunding()
    entrance_fee = crowd_funding.getEntranceFee() + 100
    tx = crowd_funding.fund({"from": account, "value": entrance_fee})
    tx.wait(1)
    assert crowd_funding.BalanceOfAddress(account.address) == entrance_fee
    tx2 = crowd_funding.withdraw({"from": account})
    tx2.wait(1)
    assert crowd_funding.BalanceOfAddress(account.address) == 0


def test_only_owner_can_withdraw():
    # to make sure only test in dev network
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENV:
        pytest.skip("Only for local testing")
    crowd_funding = deploy_crowdfunding()
    bad_actor = accounts.add()
    # to tell the pytest that we need the VirtualMachineError revert
    with pytest.raises(exceptions.VirtualMachineError):
        crowd_funding.withdraw({"from": bad_actor})
