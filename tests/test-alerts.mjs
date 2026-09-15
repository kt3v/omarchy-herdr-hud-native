import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
import test from 'node:test';

const alerts = vm.createContext({});
vm.runInContext(readFileSync(new URL('../Alerts.js', import.meta.url), 'utf8'), alerts);
const agent = state => ({ pane_id: 'p1', terminal_id: 't1', agent_status: state });
const events = (before, after) => Array.from(alerts.events(before, after));

test('disabling alerts clears popups, preserves unread counts, and blocks new alerts', () => {
  const source = readFileSync(new URL('../HerdrHud.qml', import.meta.url), 'utf8');
  const context = vm.createContext({
    alertsEnabled: true, alertQueue: [agent('done')], activeAlert: agent('done'),
    alertHovered: true, opened: false, overlayVisible: true, unread: { p1: true },
    saves: 0, saveState() { context.saves++; },
  });
  for (const name of ['toggleAlerts', 'clearAlerts', 'queueAlert', 'showNextAlert']) {
    const start = source.indexOf(`  function ${name}(`);
    const end = source.indexOf('\n  }', start) + 4;
    vm.runInContext(source.slice(start, end), context);
  }
  context.toggleAlerts();
  assert.equal(context.alertsEnabled, false);
  assert.equal(context.saves, 1);
  assert.match(source, /onAlertsEnabledChanged: if \(!alertsEnabled\) clearAlerts\(\)/);
  context.clearAlerts();
  assert.equal(context.activeAlert, null);
  assert.equal(context.alertHovered, false);
  context.queueAlert(agent('done'));
  context.showNextAlert();
  assert.equal(context.alertQueue.length, 0);
  assert.equal(context.activeAlert, null);
  assert.equal(context.unread.p1, true);
  context.toggleAlerts();
  assert.equal(context.alertsEnabled, true);
  assert.equal(context.saves, 2);
  assert.match(source, /typeof parsed.alertsEnabled === "boolean"/);
  assert.match(source, /alertsEnabled: alertsEnabled/);
});

test('alerts on completion and new input requests', () => {
  for (const status of ['idle', 'done', 'blocked']) assert.equal(events([agent('working')], [agent(status)]).length, 1);
  assert.equal(events([agent('idle')], [agent('blocked')]).length, 1);
});

test('queued input requests are discarded when the agent no longer needs input', () => {
  const source = readFileSync(new URL('../HerdrHud.qml', import.meta.url), 'utf8');
  const context = vm.createContext({
    alertsEnabled: true, opened: false, overlayVisible: true,
    activeAlert: null, alertQueue: [agent('blocked')],
    agentForPane: () => agent('idle'),
  });
  const start = source.indexOf('  function showNextAlert(');
  const end = source.indexOf('\n  }', start) + 4;
  vm.runInContext(source.slice(start, end), context);
  context.showNextAlert();
  assert.equal(context.activeAlert, null);
  assert.equal(context.alertQueue.length, 0);
  assert.match(source, /running: !!root.activeAlert && !root.activeAlertNeedsInput && !root.alertHovered/);
});
test('no startup, repeated idle/blocked, working, or replacement alerts', () => {
  assert.equal(events([], [agent('done')]).length, 0);
  for (const status of ['idle', 'done', 'blocked']) assert.equal(events([agent(status)], [agent(status)]).length, 0);
  assert.equal(events([agent('idle')], [agent('working')]).length, 0);
  assert.equal(events([agent('working')], [{ ...agent('done'), terminal_id: 'replacement' }]).length, 0);
});

function unreadContext() {
  const source = readFileSync(new URL('../HerdrHud.qml', import.meta.url), 'utf8');
  const context = vm.createContext({
    Alerts: alerts, demoMode: false, alertBaseline: false, agents: [], unread: {},
    lastSequence: {}, workingSince: {}, opened: false, selectedPane: '',
    activeAlert: null, activeAlertNeedsInput: false, connected: false, errorText: '',
    dataRevision: 0,
    agentForPane(pane) {
      for (const item of context.agents) if (String(item.pane_id || '') === pane) return item;
      return null;
    },
    selectAgent(pane) {
      context.selectedPane = pane;
      const next = { ...context.unread };
      delete next[pane];
      context.unread = next;
    },
    queueAlert() {}, clearAlerts() { context.activeAlert = null; }, showNextAlert() {},
  });
  context.root = context;
  for (const name of ['stateSequence', 'isUnreadTransition', 'cloneObject', 'applyRoster']) {
    const start = source.indexOf(`  function ${name}(`);
    vm.runInContext(source.slice(start, source.indexOf('\n  }', start) + 4), context);
  }
  return context;
}

const unreadRow = (status, stateChangeSeq, revision, pane = 'p', terminal = 't') => ({
  pane_id: pane, terminal_id: terminal, agent_status: status,
  state_change_seq: stateChangeSeq, revision,
});

test('unread never falls back to the churning revision counter', () => {
  const hud = unreadContext();
  const poll = rows => hud.applyRoster(JSON.stringify({ agents: rows }), '', 0);
  poll([unreadRow('working', 0, 1)]);
  poll([unreadRow('blocked', 0, 2)]);
  assert.equal(hud.unread.p, true, 'blocking is an unseen update');
  hud.selectAgent('p');
  assert.notEqual(hud.unread.p, true, 'selecting clears the badge');
  for (let revision = 3; revision < 8; revision++) poll([unreadRow('blocked', 0, revision)]);
  assert.notEqual(hud.unread.p, true, 'revision churn must not resurrect the badge');
  for (let sequence = 1; sequence < 4; sequence++) poll([unreadRow('blocked', sequence, 8)]);
  assert.notEqual(hud.unread.p, true, 'a same-status sequence bump must not resurrect the badge');
});

test('unread uses state transitions and ignores sequence resets and seen bookkeeping', () => {
  const hud = unreadContext();
  const poll = rows => hud.applyRoster(JSON.stringify({ agents: rows }), '', 0);
  poll([unreadRow('blocked', 10, 1)]);
  poll([unreadRow('idle', 3, 1)]);
  assert.notEqual(hud.unread.p, true, 'a sequence reset after restart is not a new update');
  poll([unreadRow('done', 4, 1)]);
  assert.notEqual(hud.unread.p, true, 'idle/done seen bookkeeping stays read');
  poll([unreadRow('working', 5, 1)]);
  poll([unreadRow('idle', 6, 1)]);
  assert.equal(hud.unread.p, true, 'finishing a turn is an unseen update');
});
