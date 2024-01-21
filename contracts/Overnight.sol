// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.0/contracts/access/Ownable.sol";
import "./math.sol";

interface ITPFt {
    function balanceOf(address) external returns (uint);
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function decimals() external returns (uint);
    function totalSupply() external returns (uint);
    function privilegedTransfer(address, address, uint) external returns (bool);
    function getTokenPrice() external returns (uint256);
}

interface IBRLt {
    function balanceOf(address) external returns (uint);
    function name() external returns (string memory);
    function symbol() external returns (string memory);
    function decimals() external returns (uint);
    function totalSupply() external returns (uint);
    function privilegedTransfer(address, address, uint) external returns (bool);
}

contract Overnight is Ownable, DSMath {
    struct LiquidityProvidedInfo {
        address provider;
        uint256 amount;
    }

    address public BRLtAddress;
    mapping(address => bool) public privilegedAccounts; // Serviços governamentais e bancos;
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
        address[] liquidityProviderAddresses; // Array para armazenar os endereços dos provedores
        mapping(address => uint256) liquidityProviders; // Mapping de provedores de liquidez
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
        require(privilegedAccounts[msg.sender], "Acesso negado: conta nao privilegiada");
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
        // Criar uma nova instância de liquidityRequest diretamente no storage
        liquidityRequest storage newRequest = liquidityRequests.push();

        // Definir as propriedades da nova solicitação de liquidez
        newRequest.institution = _institution;
        newRequest.institutionAddress = msg.sender;
        newRequest.totalAmount = _totalAmount;
        newRequest.raisedAmount = 0;
        newRequest.collateralAsset = _collateralAsset;
        newRequest.collateralAmount = (_totalAmount * 10 ** 18) / (ITPFt(_collateralAsset).getTokenPrice());
        newRequest.requestDate = block.timestamp;
        newRequest.status = Status.Open;

        privilegedTransferTPFt(_collateralAsset, msg.sender, address(this), newRequest.collateralAmount);

        return true;
    }

    function provideLiquidity(uint256 _liquidityRequestIndex, uint256 _provideAmount) public onlyPrivileged returns (bool) {
        require(_liquidityRequestIndex < liquidityRequests.length, "Request index out of bounds");
        require(_provideAmount <= (liquidityRequests[_liquidityRequestIndex].totalAmount - liquidityRequests[_liquidityRequestIndex].raisedAmount), "This value exceeds the value to be raised");

        privilegedTransferReal(msg.sender, liquidityRequests[_liquidityRequestIndex].institutionAddress, _provideAmount);
        liquidityRequests[_liquidityRequestIndex].raisedAmount += _provideAmount;

        // Verifica se o provedor já está na lista. Se não, adiciona.
        if (liquidityRequests[_liquidityRequestIndex].liquidityProviders[msg.sender] == 0) {
            liquidityRequests[_liquidityRequestIndex].liquidityProviderAddresses.push(msg.sender);
        }

        liquidityRequests[_liquidityRequestIndex].liquidityProviders[msg.sender] += _provideAmount;
        liquidityProvidersScore[msg.sender] += _provideAmount; 

        return true;
    }

    function payCreditors(uint256 _liquidityRequestIndex) public onlyPrivileged returns (bool) {
        require(_liquidityRequestIndex < liquidityRequests.length, "Request index out of bounds");
        liquidityRequest storage request = liquidityRequests[_liquidityRequestIndex];

        require(msg.sender == request.institutionAddress, "This request is not yours!");

        for (uint i = 0; i < request.liquidityProviderAddresses.length; i++) {
            address provider = request.liquidityProviderAddresses[i];
            uint256 amount = request.liquidityProviders[provider];

            if (amount > 0) {
                uint256 realAmount = (amount * getDailyCompoundedTokenPrice())/(10**18);

                privilegedTransferReal(msg.sender, provider, realAmount);
                // Resetar o montante para evitar re-pagamentos
                request.liquidityProviders[provider] = 0;
            }
        }
        
        privilegedTransferTPFt(request.collateralAsset, address(this), request.institutionAddress, request.collateralAmount);
        request.status = Status.Closed;

        return true;
    }

    function defaultPayment(uint256 _liquidityRequestIndex) public onlyPrivileged returns (bool) {
        require(_liquidityRequestIndex < liquidityRequests.length, "Request index out of bounds");
        liquidityRequest storage request = liquidityRequests[_liquidityRequestIndex];
        require(request.status == Status.Open, "Status closed");

        // Verificar se já passaram 24 horas desde a requestDate
        //require(block.timestamp >= (request.requestDate + 24 hours), "Cannot default before 24 hours");
        require(block.timestamp >= (request.requestDate + 86400), "Cannot default before 24 hours");

        uint256 amountProvided = request.liquidityProviders[msg.sender];
        require(amountProvided > 0, "No liquidity provided by sender");

        // Calcular a proporção do colateral que deve ser devolvida
        uint256 collateralToReturn = (amountProvided * 10 ** 18 / ITPFt(request.collateralAsset).getTokenPrice());

        // Transferir o colateral proporcional de volta para o msg.sender
        privilegedTransferTPFt(request.collateralAsset, address(this), msg.sender, collateralToReturn);

        // Atualizar o montante levantado e o montante do colateral restante na solicitação
        request.raisedAmount -= amountProvided;
        request.collateralAmount -= collateralToReturn;

        // Remover a contribuição do provedor de liquidez
        request.liquidityProviders[msg.sender] = 0;

        return true;
    }

    function privilegedTransferReal(address _from, address _to, uint256 _amount) public onlyPrivileged {
        IBRLt(BRLtAddress).privilegedTransfer(_from, _to, _amount);
    }

    function privilegedTransferTPFt(address _TPFtAddress, address _from, address _to, uint256 _amount) public onlyPrivileged {
        ITPFt(_TPFtAddress).privilegedTransfer(_from, _to, _amount);
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
