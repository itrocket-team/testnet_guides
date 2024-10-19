import axios from 'axios'

export async function fetchData(url: string) {
	try {
		const res = await axios.get(url, { timeout: 3000 })
		return res.data
	} catch (e) {
		console.error(e.message)
		return null
	}
}
