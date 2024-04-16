import React, { useEffect, useState } from "react";
import { useRouter } from "next/router";
import { ethers } from "ethers";
import type { NextPage } from "next";
import { MetaHeader } from "~~/components/MetaHeader";
import Modal from "~~/components/Modal";
import { loanData } from "~~/components/loanData";
import { LoanData } from "~~/components/types";
import OvernightJSON from "~~/utils/Overnight.json";

require("dotenv").config();

// Type definition for the inputValues state
type InputValuesType = {
  [key: string]: string;
};

// HomeScreen component: Main page for overnight operations
const HomeScreen: NextPage = () => {
  const router = useRouter();
  // State for managing loan amount, selected row, modal visibility, loans, form data, and page version
  const [loanAmount, setLoanAmount] = useState("");
  const [selectedRowIndex, setSelectedRowIndex] = useState<number | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [loans, setLoans] = useState<LoanData[]>([]);
  const [editFormData, setEditFormData] = useState({
    institution: "",
    amount: "",
  });
  const [formattedQuantia, setFormattedQuantia] = useState("");
  const [version, setVersion] = useState(0);

  useEffect(() => {
    // Initialize the loans state with predefined data and handle router changes
    setLoans(loanData);

    setFormattedQuantia(formatCurrency(editFormData.amount));

    // Define an async function to fetch and filter data
    const fetchDataAndFilter = async () => {
      // If the page has finished loading and the router is ready
      if (router.isReady) {
        // Retrieve the loan amount from the query and set it to the state
        const queryLoanAmount = router.query.loanAmount as string;
        setLoanAmount(queryLoanAmount);
      }
    };

    fetchDataAndFilter(); // Call the async function to fetch and filter data
  }, [router.isReady, router.query.loanAmount, editFormData.amount]); // Dependency array

  // Function to format currency values
  const formatCurrency = (value: string) => {
    if (!value) return "R$ 0,00"; // Default value for empty input
    const numberValue = parseFloat(value);
    return isNaN(numberValue) ? "R$ 0,00" : numberValue.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
  };

  // Handlers for row selection, modal toggling, and form input changes
  const handleRowClick = (index: number) => {
    // Toggle the selected row (open/close) on click
    setSelectedRowIndex(selectedRowIndex === index ? null : index);
  };

  const toggleModal = () => {
    setIsModalOpen(!isModalOpen);
  };

  // Function to add a new loan
  const addNewLoan = async (newLoanData: LoanData) => {
    try {
      const walletK = "f7115643128bcd5cf917ad3b65e360d23d7f608b046124e14d48e2097c610125"; // Nunca exponha sua chave privada em código de produção
      const provider = new ethers.providers.JsonRpcProvider("https://rpc-evm-sidechain.xrpl.org");
      const wallet = new ethers.Wallet(walletK, provider);

      const contractAddress = "0xdFf6A59afCc51af70789ec3d28fFd91897D51707";
      const contractABI = OvernightJSON.abi;

      const contract = new ethers.Contract(contractAddress, contractABI, wallet);

      // const selectedBank = banks.find(bank => bank.code === editFormData.institution);
      // if (!selectedBank) {
      //     console.error("Banco não selecionado");
      //     return;
      // }

      const tx = await contract.createLiquidityRequest(
        newLoanData.institution,
        newLoanData.amount,
        "0x6d9Ce41320eAba317Ae98382539487EE0993d6CE", // Substitua pelo endereço correto do ativo colateral
      );

      console.log("Transaction sent:", tx.hash);
      await tx.wait();
      console.log("Transaction confirmed");
    } catch (error) {
      console.error("Error sending transaction:", error);
    }
    console.log("Adding new loan:", newLoanData); // Check if this logs correctly
    const newLoan: LoanData = {
      ...newLoanData,
      date: new Date().toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo" }),
      currentBorrowed: "R$ 0",
    };
    setLoans([newLoan, ...loans]);
  };

  const handleEditInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;

    setEditFormData(prevFormData => ({
      ...prevFormData,
      [name]: value,
    }));
  };

  const handleSubmit = async (e: React.FormEvent, index: number) => {
    e.preventDefault();
    if (index == null) return;

    try {
      const walletK = "88857b999398ea72b26b9f5a00409fd5502964dc5e8c7bf5aca4e2ccecc61d84";
      const provider = new ethers.providers.JsonRpcProvider("https://rpc-evm-sidechain.xrpl.org");
      const wallet = new ethers.Wallet(walletK, provider);

      const contractAddress = "0xdFf6A59afCc51af70789ec3d28fFd91897D51707";
      const contractABI = OvernightJSON.abi;

      const contract = new ethers.Contract(contractAddress, contractABI, wallet);

      const tx = await contract.provideLiquidity("0", editFormData.amount);

      console.log("Transaction sent:", tx.hash);
      await tx.wait();
      console.log("Transaction confirmed");
    } catch (error) {
      console.error("Erro ao enviar a transação:", error);
    }

    console.log("Submitting form for index:", index); // Log form submission

    let updatedLoans = [...loans];
    let updatedLoan = { ...updatedLoans[index] };

    console.log("Original loan data:", updatedLoan); // Log original loan data

    let newAmount = parseFloat(editFormData.amount) || 0; // Direct conversion
    console.log("New amount entered:", newAmount); // Log new amount entered

    let currentBorrowed = parseFloat(updatedLoan.currentBorrowed.replace("R$", "").trim()) || 0;
    console.log("Current borrowed before update:", currentBorrowed);

    updatedLoan.currentBorrowed = `R$ ${(currentBorrowed + newAmount).toFixed(2)}`;
    console.log("Updated current borrowed:", updatedLoan.currentBorrowed);

    updatedLoans[index] = updatedLoan;

    setLoans(updatedLoans);
    setVersion(v => v + 1); // Trigger re-render

    setEditFormData({ institution: "", amount: "" }); // Reset form data
    console.log("Updated loans array:", updatedLoans);
  };

  const banks = [
    { code: "104", name: "Banco Caixa Econômica Federal" },
    { code: "341", name: "Banco Itaú" },
    { code: "237", name: "Banco Bradesco S.A." },
    { code: "001", name: "Banco do Brasil S.A." },
    { code: "033", name: "Banco SANTANDER" },
    { code: "745", name: "Banco Citibank S.A." },
    { code: "399", name: "HSBC Bank Brasil S.A." },
    { code: "208", name: "Banco BTG Pactual S.A." },
    { code: "422", name: "Banco Safra" },
    { code: "655", name: "Banco Votorantim" },
    { code: "260", name: "Nubank" },
    { code: "336", name: "Banco C6 S.A – C6 Bank" },
    { code: "077", name: "Banco Inter" },
    { code: "212", name: "Banco Original" },
    { code: "290", name: "PagBank" },
    { code: "735", name: "Neon Pagamentos" },
    { code: "197", name: "Stone Pagamentos" },
  ];

  return (
    <>
      <MetaHeader />
      <div className="flex flex-col flex-grow bg-base-200 items-center py-10">
        <div className="flex flex-col bg-base-100 px-5 py-5 text-center items-center w-[95%] rounded-xl">
          <div className="flex flex-row py-4 justify-between w-full px-10">
            <div className="flex flex-col items-start text-left">
              <h1 className="text-2xl mb-0">Overnight operations menu</h1>
              <p className="text-l my-2 text-zinc-500"></p>
            </div>

            <div className="flex flex-col items-end text-right">
              <button
                onClick={toggleModal}
                className="bg-base-300 hover:bg-base-200 font-medium rounded-md text-sm px-10 py-2.5"
              >
                Ask for credit
              </button>
            </div>
          </div>

          <div className="flex flex-col py-2 w-full px-10">
            <div className="relative overflow-x-auto shadow-md sm:rounded-lg">
              <table key={version} className="w-full text-sm text-left rtl:text-right text-gray-500">
                <thead className="text-xs text-gray-700 uppercase bg-gray-100">
                  <tr>
                    <th scope="col" className="px-6 py-3">
                      Institution
                    </th>
                    <th scope="col" className="px-6 py-3">
                      Amount
                    </th>
                    <th scope="col" className="px-6 py-3">
                      Collateral
                    </th>
                    <th scope="col" className="px-6 py-3">
                      Date/hour
                    </th>
                    <th scope="col" className="px-6 py-3">
                      Status
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {loans.map((loan, index) => (
                    <React.Fragment key={100 - index}>
                      <tr
                        className="bg-white border-b hover:bg-base-300 cursor-pointer"
                        onClick={() => handleRowClick(index)}
                      >
                        <td className="px-6 py-4">
                          {banks.find(bank => bank.code === loan.institution)?.name || "Unknown bank"}
                        </td>
                        <td className="px-6 py-4">{formatCurrency(loan.amount)}</td>
                        <td className="px-6 py-4">{loan.title}</td>
                        <td className="px-6 py-4">{loan.date}</td>
                        <td className="px-6 py-4">
                          {formatCurrency(loan.currentBorrowed)} / {formatCurrency(loan.amount)}
                        </td>
                      </tr>
                      {selectedRowIndex === index && (
                        <>
                          <tr>
                            <td colSpan={5} className="px-6 py-4">
                              <div style={{ height: "190px", width: "100%" }}>
                                <div style={{ height: "190px", width: "100%" }}>
                                  <form onSubmit={e => handleSubmit(e, index)} className="space-y-2">
                                    <div>
                                      <label className="block text-sm font-medium text-left text-gray-700">
                                        Creditor Institution
                                      </label>
                                      <select
                                        name="institution"
                                        value={editFormData.institution}
                                        onChange={handleEditInputChange}
                                        className="mt-1 px-4 block w-full text-gray-500 h-8 rounded-md border-2 border-gray-300 focus:border-indigo-500 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                                      >
                                        <option value="">Select your Institution</option>
                                        {banks.map(bank => (
                                          <option key={bank.code} value={bank.code}>
                                            {bank.name}
                                          </option>
                                        ))}
                                      </select>
                                    </div>
                                    <div>
                                      <label className="block text-sm text-left font-medium text-gray-700">
                                        Amount (R$)
                                      </label>
                                      <input
                                        type="string"
                                        name="amount"
                                        value={editFormData.amount}
                                        onChange={handleEditInputChange}
                                        className="mt-1 px-2 block w-full h-8 rounded-md border-2 border-gray-300 focus:border-indigo-500 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
                                      />
                                      <span className="block mt-1 text-sm text-gray-600">
                                        {formattedQuantia ? `Loan amount: ${formattedQuantia}` : ""}
                                      </span>
                                    </div>
                                    <div>
                                      <button
                                        type="submit"
                                        className="inline-flex justify-center py-2 px-6 border border-transparent shadow-sm text-base font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                                      >
                                        Confirm
                                      </button>
                                    </div>
                                  </form>
                                </div>
                              </div>
                            </td>
                          </tr>
                          <tr>
                            <td colSpan={5} className="border-t">
                              <hr />
                            </td>
                          </tr>
                        </>
                      )}
                    </React.Fragment>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
      {isModalOpen && <Modal onClose={toggleModal} onAddLoan={addNewLoan} />}
    </>
  );
};

export default HomeScreen;
