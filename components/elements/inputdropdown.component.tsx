import React from "react";

const InputWithDropdown = ({name}: {name: string}) => {
  return (
    <div className="relative mt-2 rounded-md shadow-sm">
      <input
        required
        type="text"
        name={name}
        id={name}
        className="block w-full rounded-md border-0 py-3 pl-4 pr-20 text-gray-900 ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
        placeholder="0"
      />
      <div className="absolute inset-y-0 right-0 flex items-center">
        <label htmlFor="currency" className="sr-only">
          Currency
        </label>
        <select
          id="currency"
          name="currency"
          className="h-full rounded-md border-0 bg-transparent py-0 pl-2 pr-7 text-gray-500 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm"
        >
          <option>COMC</option>
          <option>SAMC</option>
        </select>
      </div>
    </div>
  );
};

export default InputWithDropdown;
