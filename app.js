"use strict";

/* Datos de demostración. "dias" = días desde hoy hasta el vencimiento. */
const DATOS = [
  { num: "CT-2026-001", objeto: "Construcción de cancha polifuncional", contratista: "Constructora Andina S.R.L.", tipo: "Obra", dias: -6, resp: "Ing. M. Choque",
    hist: ["Registro del contrato", "Orden de proceder emitida", "Alerta de vencimiento enviada"] },
  { num: "CT-2026-002", objeto: "Provisión de material de escritorio", contratista: "Papelería Ingavi", tipo: "Bienes", dias: 9, resp: "Lic. R. Mamani",
    hist: ["Registro del contrato", "Recepción parcial de bienes"] },
  { num: "CT-2026-003", objeto: "Consultoría de supervisión de obra vial", contratista: "J. Quispe (consultor individual)", tipo: "Consultoría", dias: 14, resp: "Ing. M. Choque",
    hist: ["Registro del contrato", "Informe mensual aprobado"] },
  { num: "CT-2026-004", objeto: "Servicio de limpieza de oficinas", contratista: "Servicios Altiplano", tipo: "Servicios", dias: 38, resp: "Lic. P. Condori",
    hist: ["Registro del contrato", "Ampliación de plazo solicitada"] },
  { num: "CT-2026-005", objeto: "Mantenimiento de vehículos municipales", contratista: "Taller Mecánico El Alto", tipo: "Servicios", dias: 57, resp: "Lic. R. Mamani",
    hist: ["Registro del contrato"] },
  { num: "CT-2026-006", objeto: "Provisión de luminarias LED", contratista: "Electro Bolivia S.A.", tipo: "Bienes", dias: 84, resp: "Lic. P. Condori",
    hist: ["Registro del contrato", "Garantía de cumplimiento registrada"] },
  { num: "CT-2026-007", objeto: "Ampliación de red de agua potable, tramo 2", contratista: "Constructora Ingavi Ltda.", tipo: "Obra", dias: 140, resp: "Ing. M. Choque",
    hist: ["Registro del contrato", "Orden de proceder emitida", "Planilla de avance N.º 1"] },
  { num: "CT-2026-008", objeto: "Servicio de internet institucional", contratista: "Tel Altiplano S.A.", tipo: "Servicios", dias: 215, resp: "Lic. P. Condori",
    hist: ["Registro del contrato"] }
];

const HOY = new Date(); HOY.setHours(0, 0, 0, 0);
const fmt = d => d.toLocaleDateString("es-BO", { day: "2-digit", month: "2-digit", year: "numeric" });
const $ = id => document.getElementById(id);

const CONTRATOS = DATOS.map(c => {
  const f = new Date(HOY); f.setDate(f.getDate() + c.dias);
  return { ...c, fecha: f };
});

const CLASES = { "Vigente": ["b-v", ""], "Próximo a vencer": ["b-p", "f-p"], "Crítico": ["b-c", "f-c"], "Vencido": ["b-x", "f-x"] };

function estadoDe(dias, umbral) {
  if (dias < 0) return "Vencido";
  if (dias <= 15) return "Crítico";
  if (dias <= umbral) return "Próximo a vencer";
  return "Vigente";
}
const umbral = () => Number($("umbral").value);
const conEstado = () => CONTRATOS.map(c => ({ ...c, estado: estadoDe(c.dias, umbral()) }));

/* ---- Tabla, KPIs y banner ---- */
function render() {
  const todos = conEstado();
  const q = $("q").value.trim().toLowerCase();
  const est = $("estado").value;
  let lista = todos.filter(c =>
    (!q || [c.num, c.objeto, c.contratista].some(t => t.toLowerCase().includes(q))) &&
    (!est || c.estado === est));
  lista.sort($("orden").value === "num" ? (a, b) => a.num.localeCompare(b.num) : (a, b) => a.dias - b.dias);

  $("tbody").innerHTML = lista.map(c => `
    <tr class="${CLASES[c.estado][1]}">
      <td><strong>${c.num}</strong></td>
      <td>${c.objeto}</td>
      <td>${c.contratista}</td>
      <td>${fmt(c.fecha)}</td>
      <td>${c.dias < 0 ? "-" + Math.abs(c.dias) : c.dias}</td>
      <td><span class="badge ${CLASES[c.estado][0]}">${c.estado}</span></td>
      <td>${c.resp}</td>
      <td><button class="link" data-hist="${c.num}">Historial</button></td>
    </tr>`).join("");
  $("vacio").hidden = lista.length > 0;

  const cuenta = e => todos.filter(c => c.estado === e).length;
  const kp = [["Vigente", "k-v"], ["Próximo a vencer", "k-p"], ["Crítico", "k-c"], ["Vencido", "k-x"]];
  $("kpis").innerHTML = kp.map(([e, k]) =>
    `<button class="kpi ${k}" data-filtro="${e}"><b>${cuenta(e)}</b><span>${e}</span></button>`).join("");

  const urg = cuenta("Crítico") + cuenta("Vencido");
  const prox = cuenta("Próximo a vencer");
  const b = $("banner");
  if (urg + prox === 0) { b.hidden = true; return; }
  b.hidden = false;
  b.className = "banner" + (urg ? " rojo" : "");
  b.textContent = `Atención: ${cuenta("Vencido")} vencido(s), ${cuenta("Crítico")} crítico(s) y ${prox} próximo(s) a vencer en los próximos ${umbral()} días.`;
}

/* ---- Historial (según perfil) ---- */
function abrirHistorial(num) {
  if ($("rol").value === "consulta") { mensaje("bot", "Tu perfil de Consulta no tiene permiso para ver el historial."); return; }
  const c = CONTRATOS.find(x => x.num === num);
  $("dlgTitulo").textContent = `Historial · ${c.num}`;
  $("dlgLista").innerHTML = c.hist.map(h => `<li>${h}</li>`).join("");
  $("dlg").showModal();
}

/* ---- Asistente: reglas sobre los datos registrados ---- */
function mensaje(quien, texto) {
  const d = document.createElement("div");
  d.className = "m " + quien; d.textContent = texto;
  $("log").appendChild(d); $("log").scrollTop = $("log").scrollHeight;
}
function responder(texto) {
  const t = texto.toLowerCase();
  const todos = conEstado();
  const m = t.match(/ct-?\s?\d{4}-?\s?(\d{3})/) || t.match(/\b(\d{3})\b/);
  const c = m && todos.find(x => x.num.endsWith(m[1]));
  if (c) {
    if (/responsable|encargado/.test(t)) return `El responsable de ${c.num} es ${c.resp}.`;
    if (/historial|cambios/.test(t)) {
      if ($("rol").value === "consulta") return "Tu perfil no tiene permiso para ver el historial.";
      return `Historial de ${c.num}:\n• ` + c.hist.join("\n• ");
    }
    return `${c.num} (${c.objeto}) vence el ${fmt(c.fecha)}. Estado: ${c.estado}. Responsable: ${c.resp}.`;
  }
  if (/vencid/.test(t)) {
    const l = todos.filter(x => x.estado === "Vencido");
    return l.length ? "Contratos vencidos:\n• " + l.map(x => `${x.num} (${fmt(x.fecha)})`).join("\n• ") : "No hay contratos vencidos.";
  }
  if (/pronto|pr[óo]xim|vencer|alerta|cr[íi]tic/.test(t)) {
    const l = todos.filter(x => x.estado === "Próximo a vencer" || x.estado === "Crítico").sort((a, b) => a.dias - b.dias);
    return l.length ? `Vencen en los próximos ${umbral()} días:\n• ` + l.map(x => `${x.num} · ${fmt(x.fecha)} · ${x.estado}`).join("\n• ") : "No hay contratos por vencer en ese plazo.";
  }
  if (/cu[áa]ntos|resumen|total/.test(t))
    return `Hay ${todos.length} contratos registrados: ` + ["Vigente", "Próximo a vencer", "Crítico", "Vencido"].map(e => `${todos.filter(x => x.estado === e).length} ${e.toLowerCase()}`).join(", ") + ".";
  return "Solo puedo responder con los datos registrados. Prueba con: “¿Qué contratos vencen pronto?” o “Estado del contrato 003”.";
}

/* ---- Eventos ---- */
["q", "estado", "umbral", "orden"].forEach(id => $(id).addEventListener("input", render));
$("rol").addEventListener("change", () => mensaje("bot", `Perfil cambiado a: ${$("rol").selectedOptions[0].text}.`));
document.addEventListener("click", e => {
  const h = e.target.closest("[data-hist]"); if (h) abrirHistorial(h.dataset.hist);
  const k = e.target.closest("[data-filtro]");
  if (k) { $("estado").value = $("estado").value === k.dataset.filtro ? "" : k.dataset.filtro; render(); }
  const s = e.target.closest("[data-sug]"); if (s) enviar(s.dataset.sug);
});
$("dlgCerrar").addEventListener("click", () => $("dlg").close());
function enviar(texto) {
  if (!texto.trim()) return;
  mensaje("user", texto); mensaje("bot", responder(texto));
}
$("chatForm").addEventListener("submit", e => { e.preventDefault(); enviar($("msg").value); $("msg").value = ""; });

["¿Qué contratos vencen pronto?", "Estado del contrato 003", "¿Quién es el responsable del 002?", "Resumen"].forEach(s => {
  const b = document.createElement("button"); b.type = "button"; b.dataset.sug = s; b.textContent = s;
  $("sugeridas").appendChild(b);
});
mensaje("bot", "Hola. Consulto fechas, estados y responsables con los datos registrados en el sistema.");
render();
