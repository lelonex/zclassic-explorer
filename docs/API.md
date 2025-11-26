# API Reference - Zclassic Explorer

Documentazione completa delle API REST dell'explorer.

## Base URL

```
Development: http://localhost:4000/api
Production: https://zclassicexplorer.com/api
```

## Autenticazione

Le API pubbliche NON richiedono autenticazione. Rate limiting: 100 richieste/minuto per IP.

## Response Format

Tutte le risposte sono in formato JSON:

```json
{
  "success": true,
  "data": { ... },
  "timestamp": 1234567890
}
```

Errori:

```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

## Endpoints

### Blockchain

#### GET /blockchain/info

Informazioni generali sulla blockchain.

**Response:**
```json
{
  "success": true,
  "data": {
    "chain": "main",
    "blocks": 1234567,
    "headers": 1234567,
    "bestblockhash": "00000000...",
    "difficulty": 1234.567,
    "verificationprogress": 0.999999,
    "chainwork": "000000000000...",
    "pruned": false,
    "size_on_disk": 12345678901
  }
}
```

#### GET /blockchain/stats

Statistiche blockchain aggregate.

---

### Blocks

#### GET /blocks

Lista blocchi recenti.

**Query Parameters:**
- `limit` (default: 20, max: 100)
- `offset` (default: 0)

**Example:**
```bash
curl "http://localhost:4000/api/blocks?limit=10&offset=0"
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "hash": "00000000...",
      "height": 123456,
      "time": 1234567890,
      "txcount": 10,
      "size": 2048,
      "difficulty": 123.45
    }
  ]
}
```

#### GET /block/:hash

Dettagli blocco per hash.

**Response:**
```json
{
  "success": true,
  "data": {
    "hash": "00000000...",
    "confirmations": 6,
    "height": 123456,
    "version": 4,
    "merkleroot": "abcdef...",
    "time": 1234567890,
    "nonce": "...",
    "bits": "...",
    "difficulty": 123.45,
    "chainwork": "...",
    "previousblockhash": "...",
    "nextblockhash": "...",
    "tx": ["txid1", "txid2", ...]
  }
}
```

#### GET /block/height/:height

Dettagli blocco per altezza.

---

### Transactions

#### GET /tx/:txid

Dettagli transazione.

**Response:**
```json
{
  "success": true,
  "data": {
    "txid": "abc123...",
    "version": 1,
    "locktime": 0,
    "vin": [...],
    "vout": [...],
    "blockhash": "...",
    "confirmations": 6,
    "time": 1234567890,
    "blocktime": 1234567890
  }
}
```

#### GET /rawtx/:txid

Transazione raw (hex).

---

### Addresses

#### GET /address/:address

Informazioni indirizzo.

**Response:**
```json
{
  "success": true,
  "data": {
    "address": "t1abc...",
    "balance": 123.456,
    "totalReceived": 200.0,
    "totalSent": 76.544,
    "txCount": 15
  }
}
```

#### GET /address/:address/balance

Solo balance.

#### GET /address/:address/txs

Transazioni dell'indirizzo.

**Query Parameters:**
- `limit` (default: 20)
- `offset` (default: 0)

#### GET /address/:address/utxo

UTXO (Unspent Transaction Outputs).

---

### Mempool

#### GET /mempool/info

Informazioni mempool.

**Response:**
```json
{
  "success": true,
  "data": {
    "size": 150,
    "bytes": 245760,
    "usage": 512000,
    "maxmempool": 300000000
  }
}
```

#### GET /mempool/txs

Transazioni in mempool.

---

### Network

#### GET /network/info

Informazioni rete.

**Response:**
```json
{
  "success": true,
  "data": {
    "version": 1000000,
    "subversion": "/Zclassic:1.0.0/",
    "protocolversion": 170002,
    "connections": 45,
    "networks": [...],
    "relayfee": 0.00001
  }
}
```

#### GET /network/difficulty

Difficoltà attuale.

#### GET /network/hashrate

Network hashrate (Sol/s).

**Query Parameters:**
- `blocks` (default: 120) - Numero blocchi per calcolo

#### GET /network/nodes

Nodi connessi.

---

### Mining

#### GET /mining/info

Informazioni mining.

---

### Search

#### GET /search?q=:query

Ricerca universale (blocco, tx, indirizzo).

**Response:**
```json
{
  "success": true,
  "data": {
    "type": "block|transaction|address",
    "result": { ... }
  }
}
```

## WebSocket API

### Connessione

```javascript
const socket = new WebSocket('ws://localhost:4000/socket');
```

### Channels

#### Block Updates

```javascript
channel.join('blocks:new')
  .receive('ok', resp => { console.log('Joined', resp) })
  
channel.on('new_block', payload => {
  console.log('New block:', payload);
});
```

#### Transaction Updates

```javascript
channel.join('transactions:new')
  
channel.on('new_transaction', payload => {
  console.log('New tx:', payload);
});
```

## Rate Limiting

- 100 requests/minute per IP
- Header `X-RateLimit-Remaining`
- Status 429 se superato

## Errors

| Code | Description |
|------|-------------|
| 400 | Bad Request |
| 404 | Not Found |
| 429 | Rate Limit Exceeded |
| 500 | Internal Server Error |

## Examples

### cURL

```bash
# Get blockchain info
curl http://localhost:4000/api/blockchain/info

# Get specific block
curl http://localhost:4000/api/block/00000000...

# Search
curl "http://localhost:4000/api/search?q=t1abc..."
```

### JavaScript

```javascript
async function getBlockchainInfo() {
  const response = await fetch('http://localhost:4000/api/blockchain/info');
  const data = await response.json();
  return data;
}
```

### Python

```python
import requests

response = requests.get('http://localhost:4000/api/blockchain/info')
data = response.json()
print(data)
```

## Contatti

Support: https://github.com/yourusername/zclassic-explorer/issues
