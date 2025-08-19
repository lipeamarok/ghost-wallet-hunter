// src/components/results/TimelineEvents.jsx
import React from "react";

const eventIcons = {
  blacklist: "⛔",
  mixer: "🔄",
  exchange: "💱",
  cluster: "🕸️",
  received: "⬇️",
  sent: "⬆️",
  other: "ℹ️"
};
const colorByType = {
  blacklist: "border-red-500",
  mixer: "border-yellow-400",
  exchange: "border-blue-400",
  cluster: "border-violet-400",
  received: "border-green-400",
  sent: "border-orange-400",
  other: "border-gray-500"
};

export default function TimelineEvents({ events }) {
  const list = (events || []).filter(Boolean);
  if (list.length === 0) {
    return (
      <div className="w-full mt-7 mb-5">
        <div className="font-bold text-gray-200 mb-3 text-lg">🗓️ Relevant Events</div>
        <div className="text-xs text-gray-500">No relevant derived events.</div>
      </div>
    );
  }
  return (
    <div className="w-full mt-7 mb-5">
      <div className="font-bold text-gray-200 mb-3 text-lg">🗓️ Relevant Events</div>
      <div className="flex flex-col gap-4">
        {list.map((ev, i) => (
          <div
            key={i}
            className={`flex items-start gap-3 border-l-4 pl-4 py-2 bg-[#111c2b99] rounded-md shadow-sm ${colorByType[ev.type] || "border-gray-500"}`}
          >
            <span className="text-2xl select-none">{eventIcons[ev.type] || "ℹ️"}</span>
            <div className="flex-1">
              <div className="text-gray-100 text-sm">{ev.text}</div>
              <div className="text-xs text-gray-400 mt-0.5">{ev.date}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
