import { ripemd160, Ripemd160, sha256 } from '@cosmjs/crypto'
import { fromBase64, fromBech32, toBech32, toHex } from '@cosmjs/encoding'
import { ConsensusPubkey } from '../types'

export function decodeAddress(address: string) {
	return fromBech32(address)
}

function pubkeyToBech32Address(pubkeyBase64: string, prefix: string): string {
	const pubkeyBytes = fromBase64(pubkeyBase64)
	const shaHash = sha256(pubkeyBytes)
	const ripemdHash = ripemd160(shaHash)
	return toBech32(prefix, ripemdHash)
}

export function valoperToPrefix(valoper?: string) {
	if (!valoper) return ''
	const prefixIndex = valoper.indexOf('valoper')
	if (prefixIndex === -1) return null
	return valoper.slice(0, prefixIndex)
}

export function accountAddressToPrefix(account?: string) {
	if (!account) return ''

	const prefixIndex = account.indexOf('1')
	if (prefixIndex === -1) return null

	return account.slice(0, prefixIndex)
}

export function operatorAddressToAccount(operAddress?: string) {
	if (!operAddress) return ''
	const { prefix, data } = fromBech32(operAddress)
	if (prefix === 'iva') {
		// handle special cases
		return toBech32('iaa', data)
	}
	if (prefix === 'crocncl') {
		// handle special cases
		return toBech32('cro', data)
	}
	return toBech32(prefix.replace('valoper', ''), data)
}

export function consensusPubkeyToHexAddress(consensusPubkey?: { '@type': string; key: string }) {
	if (!consensusPubkey) return ''
	let raw = ''
	if (consensusPubkey['@type'] === '/cosmos.crypto.ed25519.PubKey') {
		const pubkey = fromBase64(consensusPubkey.key)
		if (pubkey) return toHex(sha256(pubkey)).slice(0, 40).toUpperCase()
	}

	if (consensusPubkey['@type'] === '/cosmos.crypto.secp256k1.PubKey') {
		const pubkey = fromBase64(consensusPubkey.key)
		if (pubkey) return toHex(new Ripemd160().update(sha256(pubkey)).digest())
	}
	return raw
}

export function pubKeyToValcons(consensusPubkey: ConsensusPubkey, prefix: string): string {
	if (!consensusPubkey) return ''
	const type = (consensusPubkey['@type'] || consensusPubkey?.type)?.toLowerCase()
	if (!type) return ''

	let raw = ''
	if (type.indexOf('ed25519') !== -1) {
		const keyBase64 = consensusPubkey.key ?? consensusPubkey.value
		if (keyBase64) {
			const addressData = sha256(fromBase64(keyBase64)).slice(0, 20)
			return toBech32(`${prefix}valcons`, addressData)
		}
	} else if (type.indexOf('secp256k1') !== -1) {
		const keyBase64 = consensusPubkey.key ?? consensusPubkey.value
		if (!keyBase64) return ''
		return pubkeyToBech32Address(keyBase64, `${prefix}valcons`)
	}
	return raw
}

export function pubKeyToValoper(consensusPubkey: ConsensusPubkey, prefix: string): string {
	const keyBase64 = consensusPubkey.key ?? consensusPubkey.value

	if (keyBase64) {
		const pubkey = fromBase64(keyBase64)
		const shaHash = sha256(pubkey)
		const addressData = ripemd160(shaHash)
		return toBech32(`${prefix}valoper`, addressData)
	}

	return ''
}

export function hexToValcons(hexAddress: string, prefix: string): string {
	// Decode the hex string into bytes
	const addressBytes = Buffer.from(hexAddress, 'hex')
	// Encode the bytes into Bech32 format with the desired prefix
	const bech32Address = toBech32(prefix, addressBytes)
	return bech32Address
}

export function valconsToBase64(address: string) {
	if (address) return toHex(fromBech32(address).data).toUpperCase()
	return ''
}

export function toETHAddress(cosmosAddress: string) {
	return `0x${toHex(fromBech32(cosmosAddress).data)}`
}

export function addressEnCode(prefix: string, pubkey: Uint8Array) {
	return toBech32(prefix, pubkey)
}
