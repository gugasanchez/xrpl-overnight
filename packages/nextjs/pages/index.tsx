// login.tsx
import React, { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { useRouter } from "next/router";

// The Login component for user authentication
const Login: React.FC = () => {
  // State to store email and password input
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const [inputValue, setInputValue] = useState("");
  const router = useRouter();

  // Handler for form submission
  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    router.push("/home-screen");
  };

  return (
    <div className="flex flex-col h-screen bg-base-200">
      <div className="grid place-items-center mx-2 my-20 sm:my-auto">
        <div
          className="w-11/12 p-12 sm:w-8/12 md:w-6/12 lg:w-5/12 2xl:w-4/12 
            px-6 py-10 sm:px-10 sm:py-6 
            bg-base-100 rounded-lg shadow-md lg:shadow-lg"
        >
          <h2 className="text-center mt-8 font-semibold text-3xl lg:text-4xl text-gray-800">
            Welcome to <br />
            XRPL Overnight!
          </h2>
          <form className="mt-10" onSubmit={handleSubmit}>
            <label htmlFor="email" className="block text-xs font-semibold text-gray-700 uppercase">
              Email
            </label>
            <input
              id="email"
              type="email"
              name="email"
              placeholder="Insert your email"
              autoComplete="email"
              className="block w-full py-3 px-1 mt-2 
                text-gray-800 appearance-none 
                border-b-2 border-gray-300
                focus:text-gray-500 focus:outline-none focus:border-indigo-300"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
            />
            <label htmlFor="password" className="block mt-10 text-xs font-semibold text-gray-700 uppercase">
              Password
            </label>
            <input
              id="password"
              type="password"
              name="password"
              placeholder="Insert your password"
              autoComplete="current-password"
              className="block w-full py-3 px-1 mt-2 mb-4
                text-gray-800 appearance-none 
                border-b-2 border-gray-300
                focus:text-gray-500 focus:outline-none focus:border-indigo-300"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
            />
            <button
              type="submit"
              className="w-full py-3 mt-10 bg-indigo-600 rounded-md
                font-medium text-white uppercase
                focus:outline-none hover:bg-indigo-700 hover:shadow-none"
            >
              Sign in
            </button>
            <div className="sm:flex sm:flex-wrap mt-8 sm:mb-4 text-sm text-center">
              <div className="flex-2 underline text-indigo-600 hover:text-indigo-800">Forgot my password</div>

              <p className="flex-1 text-gray-700 text-md mx-4 my-1 sm:my-auto">or</p>

              <div className="flex-2 underline text-indigo-600 hover:text-indigo-800">Sign up</div>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Login;
