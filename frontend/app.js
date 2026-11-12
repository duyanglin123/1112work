const apiBase = ((window.APP_CONFIG && window.APP_CONFIG.API_BASE) || "http://localhost:8000").replace(/\/$/, "");
const list = document.querySelector("#task-list");
const empty = document.querySelector("#empty");
const count = document.querySelector("#count");
const message = document.querySelector("#message");

function setMessage(text, error = false) {
  message.textContent = text;
  message.className = error ? "message error" : "message";
}

async function request(path, options = {}) {
  const response = await fetch(`${apiBase}${path}`, {
    headers: { "Content-Type": "application/json", ...(options.headers || {}) },
    ...options,
  });
  if (!response.ok) {
    const detail = await response.json().catch(() => ({}));
    throw new Error(detail.detail || `Request failed (${response.status})`);
  }
  return response.status === 204 ? null : response.json();
}

function render(tasks) {
  list.replaceChildren();
  count.textContent = tasks.length;
  empty.hidden = tasks.length !== 0;
  tasks.forEach((task) => {
    const item = document.createElement("li");
    item.className = `task ${task.completed ? "done" : ""}`;
    item.innerHTML = `
      <label class="task-main">
        <input type="checkbox" ${task.completed ? "checked" : ""} aria-label="Mark ${escapeHtml(task.title)} complete">
        <span>${escapeHtml(task.title)}</span>
      </label>
      <button class="delete" title="Delete task" aria-label="Delete ${escapeHtml(task.title)}">×</button>`;
    item.querySelector("input").addEventListener("change", async (event) => {
      try {
        await request(`/api/tasks/${task.id}`, { method: "PATCH", body: JSON.stringify({ completed: event.target.checked }) });
        await loadTasks();
      } catch (error) { setMessage(error.message, true); }
    });
    item.querySelector(".delete").addEventListener("click", async () => {
      try {
        await request(`/api/tasks/${task.id}`, { method: "DELETE" });
        await loadTasks();
      } catch (error) { setMessage(error.message, true); }
    });
    list.appendChild(item);
  });
}

function escapeHtml(value) {
  return value.replace(/[&<>'"]/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;" }[char]));
}

async function loadTasks() {
  try {
    render(await request("/api/tasks"));
    setMessage("");
  } catch (error) {
    setMessage(`Could not reach the API: ${error.message}`, true);
  }
}

document.querySelector("#task-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const input = document.querySelector("#title");
  const title = input.value.trim();
  if (!title) return;
  try {
    await request("/api/tasks", { method: "POST", body: JSON.stringify({ title }) });
    input.value = "";
    setMessage("Task added.");
    await loadTasks();
  } catch (error) { setMessage(error.message, true); }
});

loadTasks();
