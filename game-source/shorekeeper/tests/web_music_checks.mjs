// Unit test for our browser music controller, with simulated media and DOM only.
import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
const listeners = new Map(), elements = [];
let paint, deny = false, now = 0;
class Element {
  constructor(tag) { this.tag = tag; this.paused = true; this.style = {}; this.attributes = {}; this.events = new Map(); this.plays = 0; }
  set src(value) { this.attributes.src = value; }
  get src() { return this.attributes.src; }
  getAttribute(key) { return this.attributes[key] ?? null; }
  removeAttribute(key) { delete this.attributes[key]; }
  addEventListener(name, fn) { this.events.set(name, fn); }
  load() {}
  pause() { this.paused = true; }
  play() {
    this.plays++;
    if (deny) return Promise.reject(Object.assign(new Error('gesture required'), {name:'NotAllowedError'}));
    this.paused = false; return Promise.resolve();
  }
}
const document = {hidden:false, body:{append(a) { elements.push(a); }}, createElement(tag) { return new Element(tag); }, addEventListener(name, fn) { listeners.set(name, fn); }};
const context = {document,window:{},performance:{now:()=>now},requestAnimationFrame:fn=>{paint=fn;}};
vm.runInNewContext(fs.readFileSync(new URL('../web-music.js',import.meta.url),'utf8'),context);
const api = context.window.TepoMusic, [a,b,button] = elements;
const frame = () => { now+=100; paint(now); };
api.sync('title',.2,true);
for(let i=0;i<15;i++) frame();
assert.equal(a.loop,true); assert.equal(a.src,'music/title.ogg'); assert.equal(a.volume,.2);
const plays=a.plays;
for(let i=0;i<30;i++) api.sync('title',.2,true);
assert.equal(a.plays,plays,'same track must not restart on frame updates');
api.sync('combat',.2,true);
for(let i=0;i<15;i++) frame();
assert.equal(a.paused,true); assert.equal(b.src,'music/combat.ogg'); assert.equal(b.volume,.2);
api.sync('combat',.2,false); frame();
assert.equal(b.muted,true); assert.equal(b.paused,true);
api.sync('combat',.2,true); frame();
assert.equal(b.paused,false); assert.equal(b.muted,false);
document.hidden=true; listeners.get('visibilitychange')(); assert.equal(b.paused,true);
document.hidden=false; listeners.get('visibilitychange')(); assert.equal(b.paused,false);
deny=true; api.sync('late',.2,true); await Promise.resolve(); await Promise.resolve();
assert.equal(button.hidden,false,'autoplay rejection exposes a user action');
deny=false; listeners.get('pointerdown')(); await Promise.resolve(); await Promise.resolve();
assert.equal(button.hidden,true); assert.equal(a.paused,false);
api.stop(); assert.equal(a.paused,true); assert.equal(b.paused,true); assert.equal(a.getAttribute('src'),null);
console.log('WEB MUSIC: 0 errors. Crossfade, autoplay gesture, no per-frame replay, mute, visibility and stop.');
