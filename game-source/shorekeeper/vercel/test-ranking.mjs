import assert from 'node:assert/strict';
import handler from './api/ranking.js';
const strings=new Map(), hashes=new Map(), boards=new Map();
process.env.UPSTASH_REDIS_REST_URL='https://redis.invalid';
process.env.UPSTASH_REDIS_REST_TOKEN='test-only';
process.env.ALLOWED_ORIGIN='https://example.vercel.app';
globalThis.fetch=async(url,options)=>{
  assert.equal(url,'https://redis.invalid');
  const [cmd,...a]=JSON.parse(options.body);let result;
  if(cmd==='INCR'){result=(strings.get(a[0])||0)+1;strings.set(a[0],result);}
  else if(cmd==='EXPIRE')result=1;
  else if(cmd==='EVAL'){
    const [, ,key,hash,id,score,record]=a;
    if(!hashes.has(hash)) hashes.set(hash,new Map());
    if(!boards.has(key)) boards.set(key,new Map());
    if(!hashes.get(hash).has(id)){hashes.get(hash).set(id,record);boards.get(key).set(id,Number(score));}
    result=1;
  }else if(cmd==='ZREVRANGE')result=[...(boards.get(a[0])||new Map()).entries()].sort((a,b)=>b[1]-a[1]).slice(0,20).map(x=>x[0]);
  else if(cmd==='HMGET')result=a.slice(1).map(id=>hashes.get(a[0])?.get(id)||null);
  else throw new Error(cmd);
  return {ok:true,json:async()=>({result})};
};
async function call(method,body,origin='https://example.vercel.app'){
  const res={headers:{},setHeader(k,v){this.headers[k]=v;},status(c){this.code=c;return this;},json(x){this.body=x;return this;},end(){return this;}};
  await handler({method,body,headers:{origin,host:'example.vercel.app','x-forwarded-for':'127.0.0.1'},query:{mode:'shore20-v15'}},res);
  return res;
}
const row={id:'test-run-1',mode:'shore20-v15',name:'테포',seconds:1100,kills:120,level:30,won:false};
assert.equal((await call('POST',row)).code,200);
assert.equal((await call('POST',{...row,seconds:1200})).code,200);
assert.equal((await call('GET')).body.rows[0].seconds,1100,'duplicate run cannot overwrite a score');
assert.equal((await call('POST',{...row,id:'test-run-2',seconds:1200,kills:200,won:true})).code,200);
assert.equal((await call('POST',{...row,id:'test-run-3',seconds:1200,kills:201,won:true})).code,200);
assert.equal((await call('GET')).body.rows[0].kills,201);
assert.equal((await call('POST',{...row,seconds:1201})).code,400);
assert.equal((await call('POST',{...row,won:true})).code,400);
assert.equal((await call('GET',undefined,'https://other.invalid')).code,403);
assert.equal((await call('OPTIONS')).code,204);
delete process.env.UPSTASH_REDIS_REST_TOKEN;
assert.equal((await call('GET')).code,503);
console.log('RANK API: 0 errors. Ordering, idempotency, limits, origin, preflight and missing storage; mocked Redis, no deployment.');
