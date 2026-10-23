import { createHash } from 'node:crypto';
const MODE='shore20-v14';
const day=()=>new Date(Date.now()+9*3600000).toISOString().slice(0,10);
async function command(parts) {
  const response=await fetch(process.env.UPSTASH_REDIS_REST_URL,{method:'POST',headers:{Authorization:`Bearer ${process.env.UPSTASH_REDIS_REST_TOKEN}`,'Content-Type':'application/json'},body:JSON.stringify(parts)});
  if(!response.ok) throw new Error('storage unavailable');
  const data=await response.json();
  if(data.error) throw new Error('storage command failed');
  return data.result;
}
export default async function handler(req,res) {
  res.setHeader('Cache-Control','no-store');
  const origin=req.headers.origin;
  if(origin && origin!==process.env.ALLOWED_ORIGIN && origin!==`https://${req.headers.host}`) return res.status(403).json({error:'origin not allowed'});
  if(origin) {res.setHeader('Access-Control-Allow-Origin',origin);res.setHeader('Vary','Origin');}
  res.setHeader('Access-Control-Allow-Methods','GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers','Content-Type');
  if(req.method==='OPTIONS') return res.status(204).end();
  if(!['GET','POST'].includes(req.method)) return res.status(405).json({error:'method not allowed'});
  if(!process.env.UPSTASH_REDIS_REST_URL || !process.env.UPSTASH_REDIS_REST_TOKEN) return res.status(503).json({error:'ranking storage not configured'});
  const date=day(), key=`tepo:${MODE}:${date}`;
  try {
    if(req.method==='POST') {
      const row=typeof req.body==='string'?JSON.parse(req.body):req.body;
      if(!row || row.mode!==MODE || !/^[a-zA-Z0-9-]{6,80}$/.test(row.id||'') || typeof row.name!=='string' || [...row.name].length>16 || !Number.isFinite(row.seconds) || row.seconds<1 || row.seconds>1200 || !Number.isInteger(row.kills) || row.kills<0 || row.kills>200000 || !Number.isInteger(row.level) || row.level<1 || row.level>500 || (row.won===true && row.seconds!==1200)) return res.status(400).json({error:'invalid score'});
      const ip=String(req.headers['x-forwarded-for']||'unknown').split(',')[0];
      const rate=`tepo:rate:${createHash('sha256').update(ip).digest('hex').slice(0,24)}:${Math.floor(Date.now()/60000)}`;
      const count=Number(await command(['INCR',rate]));
      if(count===1) await command(['EXPIRE',rate,120]);
      if(count>6) return res.status(429).json({error:'try again later'});
      const record={id:row.id,mode:MODE,date,name:row.name.replace(/[\x00-\x1f<>]/g,'').trim()||'테포 친구',seconds:Math.floor(row.seconds*1000)/1000,kills:row.kills,level:row.level,won:row.won===true};
      // Millisecond survival dominates every possible kill-count tie break.
      const score=Math.round(record.seconds*1000)*1000000+record.kills;
      // One atomic insert per run ID, plus bounded retention for both structures.
      await command(['EVAL',"if redis.call('HEXISTS',KEYS[2],ARGV[1])==0 then redis.call('HSET',KEYS[2],ARGV[1],ARGV[3]); redis.call('ZADD',KEYS[1],ARGV[2],ARGV[1]); redis.call('EXPIRE',KEYS[1],259200); redis.call('EXPIRE',KEYS[2],259200); end; return 1",2,key,key+':rows',record.id,score,JSON.stringify(record)]);
      return res.status(200).json({accepted:true});
    }
    if(req.query?.mode && req.query.mode!==MODE) return res.status(400).json({error:'mode mismatch'});
    const ids=await command(['ZREVRANGE',key,0,19]);
    const records=ids?.length?await command(['HMGET',key+':rows',...ids]):[];
    return res.status(200).json({date,mode:MODE,rows:records.filter(Boolean).map(s=>JSON.parse(s))});
  } catch {
    return res.status(503).json({error:'ranking temporarily unavailable'});
  }
}
