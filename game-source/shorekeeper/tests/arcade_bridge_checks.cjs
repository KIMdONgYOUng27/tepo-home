// Exercise the real homepage message handler against both the export shell and runtime.
const fs=require('node:fs'), vm=require('node:vm'), assert=require('node:assert/strict');
const parentFile=process.argv[2];
if(!parentFile) throw new Error('Pass the homepage world-adventures.js path.');
const parentCode=fs.readFileSync(parentFile,'utf8');
const begin=parentCode.indexOf("addEventListener('message',event=>{");
const end=parentCode.indexOf("dialog.addEventListener('cancel'",begin);
assert(begin>=0&&end>begin,'homepage handler found');
const path=require('node:path');
const game=path.resolve(__dirname,'..');
async function check(file,fails) {
 const nodes={};
 for(const id of ['status','status-progress','status-notice','loading-percent','loading-caption']) nodes[id]={style:{},remove(){this.removed=true},removeAttribute(k){delete this[k]},appendChild(){}};
 const children={p:{},progress:{},'.game-loader':{},'.game-retry':{hidden:true}};
 const overlay={hidden:false,querySelector:key=>children[key]};
 const childToken={};let parentHandler,focused=0,cleared=0;
 const host={frame:{contentWindow:childToken,focus(){focused++}},location:{origin:'https://example.test'},dialog:{querySelector:()=>overlay},gameTimer:17,clearTimeout(){cleared++},arcadeRoom(){},addEventListener(type,handler){if(type==='message')parentHandler=handler}};
 vm.runInNewContext(parentCode.slice(begin,end),host);
 const messages=[];let requestHandler;
 const parentWindow={postMessage(data,target){assert.equal(target,host.location.origin);messages.push(data);parentHandler({data,origin:host.location.origin,source:childToken});}};
 const context={location:host.location,document:{getElementById:id=>nodes[id],createTextNode:x=>x,createElement:()=>({})},navigator:{},console:{error(){}},Promise,Error,setTimeout};
 context.window=context;context.parent=parentWindow;
 context.addEventListener=(type,handler)=>{if(type==='message')requestHandler=handler};
 context.Engine=class {
  static getMissingFeatures(){return []}
  startGame(options){
   options.onProgress(37,100);
   assert.equal(children.progress.value,37,'actual parent receives child download progress');
   options.onProgress(100,100);
   return fails?Promise.reject('fixture load failure'):Promise.resolve();
  }
 };
 vm.createContext(context);
 const html=fs.readFileSync(file,'utf8');
 for(const match of html.matchAll(/<script>([\s\S]*?)<\/script>/g)) {
  let code=match[1];
  if(!code.includes('window.TepoArcadeBridge =')&&!code.includes('const GODOT_CONFIG'))continue;
  code=code.replace('$GODOT_CONFIG','{"fileSizes":{"index.pck":1}}').replace('$GODOT_THREADS_ENABLED','false');
  vm.runInContext(code,context);
 }
 await new Promise(resolve=>setImmediate(resolve));
 if(fails){
  assert.equal(messages.at(-1).status,'error');
  assert.equal(overlay.hidden,false);
  assert.equal(children['.game-retry'].hidden,false,'error offers retry');
 } else {
  assert.equal(messages.at(-1).status,'ready');
  assert.equal(overlay.hidden,true,'homepage cover is removed only on actual engine startup');
  assert.equal(nodes.status.removed,true,'child cover also removed');
  assert(focused>0&&cleared>0,'focus and timeout are handled');
 }
 const count=messages.length;
 requestHandler({origin:'https://other.test',source:parentWindow,data:{type:'tepo-game-status-request'}});
 assert.equal(messages.length,count,'cross-origin request rejected');
 requestHandler({origin:host.location.origin,source:parentWindow,data:{type:'tepo-game-status-request'}});
 assert.equal(messages.length,count+1,'same-origin handshake replays latest status');
 const wasHidden=overlay.hidden;
 parentHandler({origin:'https://other.test',source:childToken,data:{type:'tepo-game',status:'error'}});
 assert.equal(overlay.hidden,wasHidden,'parent ignores unrelated origins');
}
(async()=>{
 const localRuntime=path.join(game,'web/index.html');
 const runtime=fs.existsSync(localRuntime)?localRuntime:path.resolve(game,'../../games/shorekeeper/index.html');
 for(const file of [path.join(game,'web-shell.html'),runtime]){
  await check(file,false);await check(file,true);
 }
 console.log('ARCADE BRIDGE: 0 errors. Actual parent + source/exported child progress, readiness, errors, focus, timeout and origin checks.');
})().catch(error=>{console.error(error);process.exitCode=1});
