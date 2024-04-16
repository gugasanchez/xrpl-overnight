import React, { useEffect, useState } from "react";
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ReferenceLine,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

const COLORS = ["#8884d8", "#82ca9d", "#ffc658", "#ff7300", "#d0ed57", "#a4de6c"];

const aggregateDataByDate = data => {
  if (!data || !Array.isArray(data)) return [];
  const aggregation = {};
  data.forEach(item => {
    if (item && item.date && item.name) {
      if (!aggregation[item.date]) {
        aggregation[item.date] = { date: item.date };
      }
      aggregation[item.date][item.name] = item.value;
    }
  });
  return Object.values(aggregation);
};

const MyBarChart = ({ data }) => {
  if (!data || data.length === 0) return <p>No data available</p>;
  const processedData = aggregateDataByDate(data);
  return (
    <BarChart
      width={730}
      height={500}
      data={processedData}
      margin={{
        top: 20,
        right: 30,
        left: 20,
        bottom: 5,
      }}
    >
      <CartesianGrid strokeDasharray="3 3" />
      <XAxis dataKey="date" />
      <YAxis />
      <Tooltip />
      <Legend />
      <ReferenceLine y={0} stroke="#000" />
      {Object.keys(processedData[0] || {})
        .filter(key => key !== "date")
        .map((key, index) => (
          <Bar key={key} dataKey={key} fill={`hsl(${index * 60}, 70%, 50%)`} stackId="a" />
        ))}
    </BarChart>
  );
};

const MultiLineTrendChart = ({ data }) => {
  if (!data || !Array.isArray(data) || data.length === 0) return <p>No data available</p>;

  const transformedData = data.reduce((acc, { name, value, date }) => {
    if (name && value && date) {
      const existingEntry = acc.find(entry => entry.date === date);
      if (existingEntry) {
        existingEntry[name] = value;
      } else {
        acc.push({ date, [name]: value });
      }
    }
    return acc;
  }, []);
  const companyNames = [...new Set(data.map(item => item.name))];

  return (
    <ResponsiveContainer width="100%" height={400}>
      <LineChart data={transformedData} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="date" />
        <YAxis />
        <Tooltip />
        <Legend />
        {companyNames.map((name, index) => (
          <Line key={name} type="monotone" dataKey={name} stroke={COLORS[index % COLORS.length]} />
        ))}
      </LineChart>
    </ResponsiveContainer>
  );
};

const transformData = data => {
  if (!data || !Array.isArray(data)) return [];
  const sortedData = data.sort((a, b) => new Date(a.date) - new Date(b.date));
  return sortedData.reduce((acc, { name, value, date }) => {
    if (name && value && date) {
      let lastEntry = acc[acc.length - 1];
      if (!lastEntry || lastEntry.date !== date) {
        lastEntry = { date };
        acc.push(lastEntry);
      }
      lastEntry[name] = (lastEntry[name] || 0) + value;
    }
    return acc;
  }, []);
};

const StackedAreaChart = ({ data }) => {
  if (!data || !Array.isArray(data) || data.length === 0) return <p>No data available</p>;
  const transformedData = transformData(data);
  const uniqueNames = [...new Set(data.map(item => item.name))];

  return (
    <ResponsiveContainer width="100%" height={400}>
      <AreaChart data={transformedData} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
        <defs>
          {uniqueNames.map((name, index) => (
            <linearGradient key={name} id={`color${name}`} x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor={COLORS[index % COLORS.length]} stopOpacity={0.8} />
              <stop offset="95%" stopColor={COLORS[index % COLORS.length]} stopOpacity={0} />
            </linearGradient>
          ))}
        </defs>
        <XAxis dataKey="date" />
        <YAxis />
        <CartesianGrid strokeDasharray="3 3" />
        <Tooltip />
        <Legend />
        {uniqueNames.map((name, index) => (
          <Area
            key={name}
            type="monotone"
            dataKey={name}
            stackId="1"
            stroke={COLORS[index % COLORS.length]}
            fillOpacity={1}
            fill={`url(#color${name})`}
          />
        ))}
      </AreaChart>
    </ResponsiveContainer>
  );
};

const DashboardPage = () => {
  const [data, setData] = useState([]);

  useEffect(() => {
    fetch(`/api/overnight-proxy`)
      .then(response => response.json())
      .then(data => {
        console.log("Fetched data:", data); // Log the data
        setData(data);
      })
      .catch(error => console.error("Error fetching data:", error));
  }, []);

  return (
    <div className="dashboard">
      <div className="chart-grid">
        <div className="chart-cell">
          <MultiLineTrendChart data={data} />
        </div>
        <div className="chart-cell">
          <MyBarChart data={data} />
        </div>
        <div className="chart-cell">
          <StackedAreaChart data={data} />
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;
