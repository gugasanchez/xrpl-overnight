# 🏛 XRPL Overnight

In most countries around the world, central banks require minimum reserves from banks and financial institutions. The reason for this is simple:

**1. Prevent excessive leverage:** By requiring banks to keep a portion of their deposits at the Central Bank, it limits the amount of money they can lend. This helps avoid excessive financial leverage and reduces the risk of financial crises.

**2. Control of Monetary Liquidity:** Compulsory deposits are a way of regulating the amount of money in circulation. By changing the compulsory deposit rate, the Central Bank can influence the volume of credit available in the economy, which impacts inflation and economic growth.

However, when banks do not have sufficient liquidity to meet reserve requirements, they often resort to interbank credit operations. These operations generally involve the use of low-risk assets, such as Treasury Bills (T-Bills) and Treasury Bonds (T-Bonds), as collateral. In the US federal funds market, banks lend and borrow from each other in overnight transactions to manage their reserves. The interest rate on these transactions is the Federal Funds Rate. Furthermore, in the Repo Market, participants use high-quality securities, such as T-Bills and T-Bonds, as collateral in short-term agreements, usually overnight.

**These operations move trillions of dollars every week** in dozens of countries around the world. Below are the data operated by some countries:

- **USA (FED):** as of June 2022, the total reserve liabilities of all depository institutions amounted to **[$20 trillion](https://www.federalregister.gov/documents/2022/12/01/2022-26065/reserve-requirements-of-depository-institutions)**.

- **Brazil (Central Bank of Brazil):** more than **[1.6 trillion BRL](https://www.correiobraziliense.com.br/economia/2020/09/4878960-operacoes-no-overnight-saltam-para-rs-16-trilhao-em-agosto.html)** (~320 billion dollars) transacted every month.

## 🎯 Challenges

However, this market faces several problems today:

1. **High Transactions Costs**: traditional interbank operations can be costly and complex, involving multiple intermediaries. Blockchain can simplify these processes, reducing operational costs.
2. **Lack of Liquidity** due to inefficiencies in communication between different financial institutions. Our platform can provide more liquidity for these operations.
3. **Transparency and Auditability:** A lack of transparency in transactions can be a challenge for regulators and auditors. Blockchain's transparent ledger allows for easier tracking and auditing of financial transactions.
4. **Counterparty Risk:** In the traditional system, there is a risk of one party failing to fulfill its obligations. Blockchain, with smart contracts, can ensure transactions are executed only when all parties meet their commitments. Additionally, we can automate these payments by using Chainlink Automate.

## 🚀 Our solution

In our solution, we developed a system for these operations for the Brazilian market for two main reasons:

1) **Timing**: Brazil has one of the most developed CBDC projects (It is called Drex and will be made in EVM) in the world and which will also tokenize national treasury bonds. So, we can transact on-chain both the CBDC and the collateral.

2) **Local Expertise:** Our team's Brazilian roots provide us with a strong understanding of the local financial market. This expertise is crucial in tailoring our system to Brazil's unique financial landscape, ensuring an effective and compliant solution.

### 📈 Business Model

- It is more difficult to get customers, but by closing a few institutional customers we already have a very large volume operated, that is, **it scales very quickly** (transaction fee-based model).
- Technology provided by the National Treasury and Central Bank together, ensuring **alignment of interests and completeness** in the operation of tokenizing national treasury bonds;
- **Strategic partnerships** with banks and financial institutions, to scale usage and promote the network effect in B2B for this solution;
- System developed with **interoperability**, so that holders of government bonds can use them as collateral **at any financial institution**;

### 💻 Robust and Innovative Technology

- **Smart Contracts** for functional and complete tokenization of treasury bonds and the Brazilian Real, simulating Drex (Brazilian CBDC) solutions;
- **Smart Contracts** for payments and credit operations with NTBt's on blockchain;
- **Chainlink Functions** to access brazilian interest rate data (Selic) from Central Bank API;
- **Chainlink Automation** to update NTBt token price according to interest rate from Central Bank API; (it runs daily)
- ParticleAuth provides a better UX/UI by making easier crypto onboarding.
- **Backend** for storing relevant off-chain data.
- API deployed and **[available](https://xrpl-api.vercel.app/overnight)** in the cloud.
- Functional and integrated **frontend** for simulation and benchmarking with an extremely simple user experience;

### 😌 Easy to use

Despite the robust technology provided by Overnight, we believe that mass adoption of this solution can only occur if it is simple for the end-user. Therefore, we have adopted a traditional Web2 login model, which stores each user's wallets to carry out these operations.

- **No need to understand Web 3**;
- **No red tape**;
- **No need to keep your private keys on your own**.

Hence, we offer Smart Contracts and APIs for banks, which will deliver a **simple journey** to obtain credit and manage these operations.

## 📼 Presentation Video
[Youtube Link](https://www.youtube.com/watch?v=csabs5zONOE)


## 📄 Smart Contracts Docs
[Link to the contracts' documentation](./docs/smartContracts.md)

## 🖥 Application Deploy
[Link to our application](https://xrp-overnight.vercel.app/)
