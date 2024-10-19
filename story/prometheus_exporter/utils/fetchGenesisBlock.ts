import { fromBase64 } from '@cosmjs/encoding'
import { fetchData } from '../lib/http'

export async function getChunkedGenesisBlock(url: string) {
	try {
		const res = await fetchData(url)

		const blockUint8Array = fromBase64(res.result.data)
		const block = JSON.parse(new TextDecoder().decode(blockUint8Array))

		return block
	} catch (e) {
		console.error(`Error retrieving chunked genesis block from ${url}: ${e.message}`)
	}
}
