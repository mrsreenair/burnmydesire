"use client";

import { useState } from "react";

const TOPICS = [
  { value: "support", label: "Something's broken", to: "support@burnmydesire.com" },
  { value: "press", label: "Press or podcast", to: "press@burnmydesire.com" },
  { value: "beta", label: "Join the TestFlight beta", to: "beta@burnmydesire.com" },
  { value: "other", label: "Something else", to: "hello@burnmydesire.com" },
];

/**
 * There is no backend to post to — that is the whole point of the product — so
 * the form composes a mail draft in the visitor's own client instead. Nothing
 * is submitted anywhere until they press send themselves.
 */
export default function ContactForm() {
  const [topic, setTopic] = useState(TOPICS[0].value);
  const [name, setName] = useState("");
  const [message, setMessage] = useState("");

  const chosen = TOPICS.find((t) => t.value === topic) ?? TOPICS[0];
  const subject = `${chosen.label}${name ? ` — ${name}` : ""}`;
  const href = `mailto:${chosen.to}?subject=${encodeURIComponent(
    subject,
  )}&body=${encodeURIComponent(message)}`;

  return (
    <form
      className="card p-8 sm:p-10"
      style={{ transform: "none" }}
      onSubmit={(e) => e.preventDefault()}
    >
      <div className="grid gap-5 sm:grid-cols-2">
        <div>
          <label className="label" htmlFor="topic">
            What&apos;s this about?
          </label>
          <select
            id="topic"
            className="field"
            value={topic}
            onChange={(e) => setTopic(e.target.value)}
          >
            {TOPICS.map((t) => (
              <option key={t.value} value={t.value}>
                {t.label}
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="label" htmlFor="name">
            Your name <span style={{ color: "var(--text-low)" }}>(optional)</span>
          </label>
          <input
            id="name"
            className="field"
            placeholder="However you'd like to be called"
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
        </div>
      </div>

      <div className="mt-5">
        <label className="label" htmlFor="message">
          Message
        </label>
        <textarea
          id="message"
          className="field"
          rows={6}
          placeholder="Tell us what happened, or what you want to know."
          value={message}
          onChange={(e) => setMessage(e.target.value)}
        />
      </div>

      <div className="mt-7 flex flex-wrap items-center gap-4">
        <a
          href={href}
          className="btn btn-dark"
          aria-disabled={message.trim().length === 0}
          style={
            message.trim().length === 0
              ? { pointerEvents: "none", opacity: 0.45 }
              : undefined
          }
        >
          Open in your mail app
        </a>
        <p className="fine max-w-[34ch]">
          This composes a draft on your device. Nothing is sent until you press
          send — and nothing is stored here at all.
        </p>
      </div>
    </form>
  );
}
