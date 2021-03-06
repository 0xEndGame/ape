import { Event } from '../Event';
import { addAction, World } from '../World';
import { ComptrollerImpl } from '../Contract/ComptrollerImpl';
import { Unitroller } from '../Contract/Unitroller';
import { invoke } from '../Invokation';
import { getAddressV, getArrayV, getEventV, getExpNumberV, getNumberV, getStringV } from '../CoreValue';
import { ArrayV, AddressV, EventV, NumberV, StringV } from '../Value';
import { Arg, Command, View, processCommandEvent } from '../Command';
import { buildComptrollerImpl } from '../Builder/ComptrollerImplBuilder';
import { ComptrollerErrorReporter } from '../ErrorReporter';
import { getComptrollerImpl, getComptrollerImplData, getUnitroller } from '../ContractLookup';
import { verify } from '../Verify';
import { mergeContractABI } from '../Networks';

async function genComptrollerImpl(world: World, from: string, params: Event): Promise<World> {
  let { world: nextWorld, comptrollerImpl, comptrollerImplData } = await buildComptrollerImpl(
    world,
    from,
    params
  );
  world = nextWorld;

  world = addAction(
    world,
    `Added Comptroller Implementation (${comptrollerImplData.description}) at address ${comptrollerImpl._address}`,
    comptrollerImplData.invokation
  );

  return world;
}

async function mergeABI(
  world: World,
  from: string,
  comptrollerImpl: ComptrollerImpl,
  unitroller: Unitroller
): Promise<World> {
  if (!world.dryRun) {
    // Skip this specifically on dry runs since it's likely to crash due to a number of reasons
    world = await mergeContractABI(world, 'Comptroller', unitroller, unitroller.name, comptrollerImpl.name);
  }

  return world;
}

async function become(
  world: World,
  from: string,
  comptrollerImpl: ComptrollerImpl,
  unitroller: Unitroller
): Promise<World> {
  let invokation = await invoke(
    world,
    comptrollerImpl.methods._become(unitroller._address),
    from,
    ComptrollerErrorReporter
  );

  if (!world.dryRun) {
    // Skip this specifically on dry runs since it's likely to crash due to a number of reasons
    world = await mergeContractABI(world, 'Comptroller', unitroller, unitroller.name, comptrollerImpl.name);
  }

  world = addAction(world, `Become ${unitroller._address}'s Comptroller Impl`, invokation);

  return world;
}

async function verifyComptrollerImpl(
  world: World,
  comptrollerImpl: ComptrollerImpl,
  name: string,
  contract: string,
  apiKey: string
): Promise<World> {
  if (world.isLocalNetwork()) {
    world.printer.printLine(`Politely declining to verify on local network: ${world.network}.`);
  } else {
    await verify(world, apiKey, name, contract, comptrollerImpl._address);
  }

  return world;
}

export function comptrollerImplCommands() {
  return [
    new Command<{ comptrollerImplParams: EventV }>(
      `
        #### Deploy

        * "ComptrollerImpl Deploy ...comptrollerImplParams" - Generates a new Comptroller Implementation
          * E.g. "ComptrollerImpl Deploy MyScen Scenario"
      `,
      'Deploy',
      [new Arg('comptrollerImplParams', getEventV, { variadic: true })],
      (world, from, { comptrollerImplParams }) => genComptrollerImpl(world, from, comptrollerImplParams.val)
    ),
    new View<{ comptrollerImplArg: StringV; apiKey: StringV }>(
      `
        #### Verify

        * "ComptrollerImpl <Impl> Verify apiKey:<String>" - Verifies Comptroller Implemetation in Etherscan
          * E.g. "ComptrollerImpl Verify "myApiKey"
      `,
      'Verify',
      [new Arg('comptrollerImplArg', getStringV), new Arg('apiKey', getStringV)],
      async (world, { comptrollerImplArg, apiKey }) => {
        let [comptrollerImpl, name, data] = await getComptrollerImplData(world, comptrollerImplArg.val);

        return await verifyComptrollerImpl(world, comptrollerImpl, name, data.get('contract')!, apiKey.val);
      },
      { namePos: 1 }
    ),

    new Command<{
      unitroller: Unitroller;
      comptrollerImpl: ComptrollerImpl;
    }>(
      `
        #### Become

        * "ComptrollerImpl <Impl> Become <Rate> <CompMarkets> <OtherMarkets>" - Become the comptroller, if possible.
          * E.g. "ComptrollerImpl MyImpl Become 0.1e18 [cDAI, cETH, cUSDC]
      `,
      'Become',
      [
        new Arg('unitroller', getUnitroller, { implicit: true }),
        new Arg('comptrollerImpl', getComptrollerImpl)
      ],
      (world, from, { unitroller, comptrollerImpl }) => {
        return become(world, from, comptrollerImpl, unitroller)
      },
      { namePos: 1 }
    ),

    new Command<{
      unitroller: Unitroller;
      comptrollerImpl: ComptrollerImpl;
    }>(
      `
        #### MergeABI

        * "ComptrollerImpl <Impl> MergeABI" - Merges the ABI, as if it was a become.
          * E.g. "ComptrollerImpl MyImpl MergeABI
      `,
      'MergeABI',
      [
        new Arg('unitroller', getUnitroller, { implicit: true }),
        new Arg('comptrollerImpl', getComptrollerImpl)
      ],
      (world, from, { unitroller, comptrollerImpl }) => mergeABI(world, from, comptrollerImpl, unitroller),
      { namePos: 1 }
    )
  ];
}

export async function processComptrollerImplEvent(
  world: World,
  event: Event,
  from: string | null
): Promise<World> {
  return await processCommandEvent<any>('ComptrollerImpl', comptrollerImplCommands(), world, event, from);
}
