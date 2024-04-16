import React, { ChangeEvent, useEffect, useState } from "react";
import Image from "next/image";
import { LoanData } from "./types";

// Type definition for the props received by the Modal component
type ModalProps = {
  onClose: () => void; // Function to be called to close the modal
  onAddLoan: (loanData: LoanData) => void; // Function to be called to add a new loan
};

// Modal component for loan operations
const Modal: React.FC<ModalProps> = ({ onClose, onAddLoan }) => {
  // State for form data, initializing with empty fields
  const [formData, setFormData] = useState<LoanData>({
    institution: "",
    amount: "",
    title: "",
    currentBorrowed: "",
  });

  // State for displaying formatted loan amount
  const [formattedQuantia, setFormattedQuantia] = useState("");
  // State for storing and displaying any error messages
  const [errorMessage, setErrorMessage] = useState("");

  // Effect to format the loan amount whenever it changes
  useEffect(() => {
    setFormattedQuantia(formatCurrency(formData.amount));
  }, [formData.amount]);

  // Function to format currency value to Brazilian Real format
  const formatCurrency = (value: string) => {
    const numberValue = parseFloat(value);
    if (!isNaN(numberValue)) {
      return numberValue.toLocaleString("pt-BR", { style: "currency", currency: "BRL" });
    }
    return "";
  };

  // Handler for input changes to update form data
  const handleInputChange = (e: ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prevFormData => ({
      ...prevFormData,
      [name]: value,
    }));
  };

  // Handler for form submission
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.institution || !formData.amount || !formData.title) {
      setErrorMessage("Please, fill all the fields.");
      return;
    }
    setErrorMessage("");

    onAddLoan({
      ...formData,
      currentBorrowed: "R$ 0",
    });
    onClose();
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

  const collateralTitles = [
    "Tesouro Selic 2025",
    "Tesouro Selic 2026",
    "Tesouro Selic 2027",
    "Tesouro Selic 2028",
    "Tesouro Selic 2029",
  ];

  return (
    // Modal structure
    <div className="fixed inset-0 bg-black bg-opacity-40 z-40" onClick={onClose}>
      <div className="fixed inset-0 z-50 flex justify-center items-center" onClick={e => e.stopPropagation()}>
        <div className="bg-white p-8 rounded-lg" style={{ width: "600px", height: "auto" }}>
          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label htmlFor="institution" className="block text-base text-left font-medium text-gray-700">
                Bank
              </label>
              <select
                name="institution"
                id="institution"
                value={formData.institution}
                onChange={handleInputChange}
                className="mt-1 px-4 block w-full text-gray-500 h-12 rounded-md border-2 border-gray-400 focus:border-indigo-500 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
              >
                <option value="">Select your bank</option>
                {banks.map(bank => (
                  <option key={bank.code} value={bank.code}>
                    {bank.name}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label htmlFor="amount" className="block text-base text-left font-medium text-gray-700">
                Amount (R$)
              </label>
              <input
                type="text"
                name="amount"
                id="amount"
                value={formData.amount}
                onChange={handleInputChange}
                className="mt-1 px-2 block w-full h-12 rounded-md border-2 border-gray-400 focus:border-indigo-500 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
              />
              <span className="block mt-1 text-sm text-gray-600">
                {formattedQuantia ? `Valor do empréstimo: ${formattedQuantia}` : ""}
              </span>
            </div>
            <div>
              <label htmlFor="title" className="block text-base text-left font-medium text-gray-700">
                Collateral title
              </label>
              <select
                name="title"
                id="title"
                value={formData.title}
                onChange={handleInputChange}
                className="mt-1 px-4 block w-full text-gray-500 h-12 rounded-md border-2 border-gray-400 focus:border-indigo-500 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
              >
                <option value="">Select title</option>
                {collateralTitles.map(title => (
                  <option key={title} value={title}>
                    {title}
                  </option>
                ))}
              </select>
            </div>
            {errorMessage && <div className="text-red-500 text-sm">{errorMessage}</div>}
            <div>
              <button
                type="submit"
                className="inline-flex justify-center py-3 px-6 border border-transparent shadow-sm text-base font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Confirm
              </button>
            </div>
          </form>
          <button className="absolute top-2 right-2" onClick={onClose}>
            <Image src="/images/cruz.png" alt="Fechar" width={24} height={24} />
          </button>
        </div>
      </div>
    </div>
  );
};

export default Modal;
