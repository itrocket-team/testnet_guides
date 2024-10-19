import express, { Request, Response } from 'express'
import * as client from 'prom-client'

import { fetchTotalSupply, fetchValidatorAddress } from '../lib/api'

const app = express()
const PORT = 8000
const FETCH_INTERVAL = 10 * 60 * 1000 // 10 minutes

client.collectDefaultMetrics()

app.get('/metrics', async (req: Request, res: Response) => {
	try {
		res.set('Content-Type', client.register.contentType)
		const metrics = await client.register.metrics()
		res.end(metrics)
	} catch (error) {
		console.error('Error generating metrics:', error)
		res.status(500).send('Error generating metrics')
	}
})

app.listen(PORT, () => {
	console.log(`Exporter running on http://localhost:${PORT}/metrics`)
})

function setupIntervalFetch(fetchFunction: () => Promise<void>, name: string) {
	const fetch = async () => {
		try {
			await fetchFunction()
		} catch (error) {
			console.error(`Error fetching ${name}:`, error)
		}
	}

	fetch()
	setInterval(fetch, FETCH_INTERVAL)
}

setupIntervalFetch(fetchTotalSupply, 'total supply')
setupIntervalFetch(fetchValidatorAddress, 'validator address')
