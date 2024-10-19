import * as client from 'prom-client'
import { getChunkedGenesisBlock } from '../utils/fetchGenesisBlock'
import { accountAddressToPrefix, consensusPubkeyToHexAddress, pubKeyToValcons, pubKeyToValoper } from './address'
import { fetchData } from './http'

const supplyGauge = new client.Gauge({
	name: 'story_chain_total_supply',
	help: 'Total Supply of the Story chain',
})

const validatorGauge = new client.Gauge({
	name: 'story_chain_validator_info',
	help: 'Information about Story chain validators',
	labelNames: [
		'operator_address',
		'moniker',
		'status',
		'tokens',
		'delegator_shares',
		'consensus_address',
		'hex_address',
		'jailed',
		'unbonding_height',
		'unbonding_time',
		'min_self_delegation',
	],
})

export async function fetchValidatorAddress(): Promise<void> {
	try {
		const base_url = 'https://api-story-testnet.itrocket.net/cosmos/staking/v1beta1/validators?status='
		const bondedValidatorsList = await fetchData(`${base_url}BOND_STATUS_BONDED`)
		const unbondedValidatorList = await fetchData(`${base_url}BOND_STATUS_UNBONDED`)
		const unbondingValidatorsList = await fetchData(`${base_url}BOND_STATUS_UNBONDING`)

		const block = await getChunkedGenesisBlock(`https://story-testnet-rpc.itrocket.net/genesis_chunked?chunk=0`)
		const account = block?.app_state.bank.balances[0].address

		const prefix = accountAddressToPrefix(account)

		if (!prefix) {
			console.warn(`Prefix not found`)
		}

		const processValidators = (validators: any[], status: string) => {
			return validators.map((validator: any) => {
				const { consensus_pubkey, ...rest } = validator

				const address: any = {}

				if (consensus_pubkey && prefix) {
					const consensusAddress = pubKeyToValcons(consensus_pubkey, prefix)
					const valoperAddress = pubKeyToValoper(consensus_pubkey, prefix)
					const hexAddress = consensusPubkeyToHexAddress(consensus_pubkey)

					address.consensus_address = consensusAddress
					address.valoper_address = valoperAddress
					address.hex_address = hexAddress
				}

				return {
					...rest,
					consensus_pubkey,
					address,
					status,
					jailed: rest.jailed || false,
					unbonding_height: rest.unbonding_height || '0',
					unbonding_time: rest.unbonding_time || '1970-01-01T00:00:00Z',
					min_self_delegation: rest.min_self_delegation || '1',
				}
			})
		}

		const processedBondedValidators = processValidators(bondedValidatorsList.validators, 'BOND_STATUS_BONDED')
		const processedUnbondedValidators = processValidators(unbondedValidatorList.validators, 'BOND_STATUS_UNBONDED')
		const processedUnbondingValidators = processValidators(unbondingValidatorsList.validators, 'BOND_STATUS_UNBONDING')

		const allProcessedValidators = [...processedBondedValidators, ...processedUnbondedValidators, ...processedUnbondingValidators]

		// Set validator information in Prometheus gauge
		allProcessedValidators.forEach((validator: any) => {
			const hexAddress = validator.address.hex_address.toUpperCase()
			validatorGauge.set(
				{
					operator_address: validator.operator_address,
					moniker: validator.description.moniker,
					status: validator.status,
					tokens: validator.tokens,
					delegator_shares: validator.delegator_shares,
					consensus_address: validator.address.consensus_address,
					hex_address: hexAddress,
					jailed: validator.jailed.toString(),
					unbonding_height: validator.unbonding_height,
					unbonding_time: validator.unbonding_time,
					min_self_delegation: validator.min_self_delegation,
				},
				1
			)
		})

		console.log(`Processed ${allProcessedValidators.length} validators`)
	} catch (e) {
		console.error(`Failed to fetch validators address info: ${e.message}`)
	}
}

export async function fetchTotalSupply() {
	try {
		const response = await fetchData('https://testnet.story.api.explorers.guru/api/v1/chain')

		const supply = response.supply || 0
		supplyGauge.set(supply)
	} catch (e) {
		console.error(`Failed to fetch total supply: ${e.message}`)
	}
}
