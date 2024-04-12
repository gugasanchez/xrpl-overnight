// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "./math.sol";
import "./IBRLt.sol";
import "./INTBt.sol";

contract Overnight is Ownable, DSMath {
    struct LiquidityProvidedInfo {
        address provider;
        uint256 amount;
    }

    address public BRLtAddress;
    mapping(address => bool) public privilegedAccounts; // Financial institutions and banks;
    mapping(address => uint256) liquidityProvidersScore; 
    uint256 interestRateDaily;

    struct liquidityRequest {
        string institution;
        address institutionAddress;
        uint256 totalAmount;
        uint256 raisedAmount;
        address collateralAsset;
        uint256 collateralAmount;
        uint256 requestDate;
        address[] liquidityProviderAddresses; // Providers addresses array
        mapping(address => uint256) liquidityProviders; // Liquidity Providers mapping
        Status status;
    }

    enum Status {
        Open,
        Closed
    }

    liquidityRequest[] public liquidityRequests;

    constructor(address _BRLtAddress) {
        BRLtAddress = _BRLtAddress;
        privilegedAccounts[msg.sender] = true;
        privilegedAccounts[address(this)] = true;
    }

    modifier onlyPrivileged() {
        require(privilegedAccounts[msg.sender], "Access Denied: account is not privileged");
        _;
    }

    function addPrivilegedAccount(address account) public onlyOwner {
        privilegedAccounts[account] = true;
    }

    function removePrivilegedAccount(address account) public onlyOwner {
        privilegedAccounts[account] = false;
    }

    //Take only the part after the 3 decimal places
    //43739 = 1,00043739
    function setInterestRateDaily(uint256 _newInterestRateDaily) public onlyPrivileged returns (bool) {
        interestRateDaily = _newInterestRateDaily;
        return true;
    }

    function createLiquidityRequest(string memory _institution, uint256 _totalAmount, address _collateralAsset) public onlyPrivileged returns(bool) {
        // Create a new instance of liquidityRequest directly in storage
        liquidityRequest storage newRequest = liquidityRequests.push();

        // Define the properties of the new liquidity request
        newRequest.institution = _institution;
        newRequest.institutionAddress = msg.sender;
        newRequest.totalAmount = _totalAmount;
        newRequest.raisedAmount = 0;
        newRequest.collateralAsset = _collateralAsset;
        newRequest.collateralAmount = (_totalAmount * 10 ** 18) / (INTBt(_collateralAsset).getTokenPrice());
        newRequest.requestDate = block.timestamp;
        newRequest.status = Status.Open;

        // Lock collateral assets on smartcontract
        privilegedTransferTPFt(_collateralAsset, msg.sender, address(this), newRequest.collateralAmount);

        return true;
    }

    function provideLiquidity(uint256 _liquidityRequestIndex, uint256 _provideAmount) public onlyPrivileged returns (bool) {
        //Check if the liquidity request exists
        require(_liquidityRequestIndex < liquidityRequests.length, "Request index out of bounds");

        //Checks whether the amount sent exceeds the liquidity request
        require(_provideAmount <= (liquidityRequests[_liquidityRequestIndex].totalAmount - liquidityRequests[_liquidityRequestIndex].raisedAmount), "This value exceeds the value to be raised");

        //Send money to the bank and register it in the system
        privilegedTransferReal(msg.sender, liquidityRequests[_liquidityRequestIndex].institutionAddress, _provideAmount);
        liquidityRequests[_liquidityRequestIndex].raisedAmount += _provideAmount;

        //Verify if the provider is already on the liquidity providers list and add him
        if (liquidityRequests[_liquidityRequestIndex].liquidityProviders[msg.sender] == 0) {
            liquidityRequests[_liquidityRequestIndex].liquidityProviderAddresses.push(msg.sender);
        }

        liquidityRequests[_liquidityRequestIndex].liquidityProviders[msg.sender] += _provideAmount;
        
        //Increase his Liquidity Score
        liquidityProvidersScore[msg.sender] += _provideAmount; 

        return true;
    }

    function payCreditors(uint256 _liquidityRequestIndex) public onlyPrivileged returns (bool) {
        require(_liquidityRequestIndex < liquidityRequests.length, "Request index out of bounds");
        liquidityRequest storage request = liquidityRequests[_liquidityRequestIndex];

        require(msg.sender == request.institutionAddress, "This request is not yours!");

        //Pay all the ones who provided liquidity with a daily interest rate (In Brazil, it is called Selic Over)
        for (uint i = 0; i < request.liquidityProviderAddresses.length; i++) {
            address provider = request.liquidityProviderAddresses[i];
            uint256 amount = request.liquidityProviders[provider];

            if (amount > 0) {
                uint256 realAmount = (amount * getDailyCompoundedTokenPrice())/(10**18);

                privilegedTransferReal(msg.sender, provider, realAmount);
                // Reset provider liquidity balance
                request.liquidityProviders[provider] = 0;
            }
        }
        
        //Send the collateral back and close the request
        privilegedTransferTPFt(request.collateralAsset, address(this), request.institutionAddress, request.collateralAmount);
        request.status = Status.Closed;

        return true;
    }

    function defaultPayment(uint256 _liquidityRequestIndex) public onlyPrivileged returns (bool) {
        // Ensure the provided request index is within bounds
        require(_liquidityRequestIndex < liquidityRequests.length, "Request index out of bounds");
        liquidityRequest storage request = liquidityRequests[_liquidityRequestIndex];

        // Ensure that the request status is Open, allowing for default
        require(request.status == Status.Open, "Status closed");

        // Check if 24 hours have passed since the requestDate
        require(block.timestamp >= (request.requestDate + 86400), "Cannot default before 24 hours");

        uint256 amountProvided = request.liquidityProviders[msg.sender];
        require(amountProvided > 0, "No liquidity provided by sender");

        // Calculate the proportion of collateral to be returned based on the provided amount
        uint256 collateralToReturn = (amountProvided * 10 ** 18 / INTBt(request.collateralAsset).getTokenPrice());

        // Transfer the proportional collateral back to the sender
        privilegedTransferTPFt(request.collateralAsset, address(this), msg.sender, collateralToReturn);

        // Update the raisedAmount and collateralAmount in the request
        request.raisedAmount -= amountProvided;
        request.collateralAmount -= collateralToReturn;

        // Remove the liquidity contribution from the provider
        request.liquidityProviders[msg.sender] = 0;

        return true;
    }

    function privilegedTransferReal(address _from, address _to, uint256 _amount) public onlyPrivileged {
        IBRLt(BRLtAddress).privilegedTransfer(_from, _to, _amount);
    }

    function privilegedTransferTPFt(address _TPFtAddress, address _from, address _to, uint256 _amount) public onlyPrivileged {
        INTBt(_TPFtAddress).privilegedTransfer(_from, _to, _amount);
    }

    function getDailyCompoundedTokenPrice() public view returns (uint256) {
        uint256 ONE_DAY_IN_SECONDS = 24 * 60 * 60;
        uint256 price = WAD; // 1 * 10 ** 18

        uint256 interestRateWad = interestRateDaily * 10 ** 10; // Convert to wad format (150 = 1.5% = 0.015)

        uint256 elapsedTime = 86400;

        uint256 compoundingPeriods = elapsedTime / ONE_DAY_IN_SECONDS;
        uint256 remainingTime = elapsedTime % ONE_DAY_IN_SECONDS;

        for (uint256 i = 0; i < compoundingPeriods; i++) {
            price = wmul(price, add(WAD, interestRateWad));
        }

        if (remainingTime > 0) {
            uint256 remainingInterest = mul(interestRateWad, remainingTime) / ONE_DAY_IN_SECONDS;
            uint256 remainingRate = add(WAD, remainingInterest);
            price = wmul(price, remainingRate);
        }

        return price;
    }
}