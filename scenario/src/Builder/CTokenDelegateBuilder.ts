import { Event } from '../Event';
import { World } from '../World';
import { CErc20Delegate, CErc20DelegateScenario } from '../Contract/CErc20Delegate';
import { Invokation } from '../Invokation';
import { getStringV } from '../CoreValue';
import { StringV } from '../Value';
import { Arg, Fetcher, getFetcherValue } from '../Command';
import { storeAndSaveContract } from '../Networks';
import { getContract, getTestContract } from '../Contract';

const CErc20DelegateContract = getContract('ApeErc20Delegate');
const CErc20DelegateScenarioContract = getTestContract('ApeErc20DelegateScenario');
const CCollateralCapErc20DelegateScenarioContract = getContract('ApeCollateralCapErc20DelegateScenario');
const CWrappedNativeDelegateScenarioContract = getContract('ApeWrappedNativeDelegateScenario');

export interface CTokenDelegateData {
  invokation: Invokation<CErc20Delegate>;
  name: string;
  contract: string;
  description?: string;
}

export async function buildCTokenDelegate(
  world: World,
  from: string,
  params: Event
): Promise<{ world: World; cTokenDelegate: CErc20Delegate; delegateData: CTokenDelegateData }> {
  const fetchers = [
    new Fetcher<{ name: StringV; }, CTokenDelegateData>(
      `
        #### CErc20Delegate

        * "CErc20Delegate name:<String>"
          * E.g. "CTokenDelegate Deploy CErc20Delegate cDAIDelegate"
      `,
      'CErc20Delegate',
      [
        new Arg('name', getStringV)
      ],
      async (
        world,
        { name }
      ) => {
        return {
          invokation: await CErc20DelegateContract.deploy<CErc20Delegate>(world, from, []),
          name: name.val,
          contract: 'ApeErc20Delegate',
          description: 'Standard CErc20 Delegate'
        };
      }
    ),

    new Fetcher<{ name: StringV; }, CTokenDelegateData>(
      `
        #### CErc20DelegateScenario

        * "CErc20DelegateScenario name:<String>" - A CErc20Delegate Scenario for local testing
          * E.g. "CTokenDelegate Deploy CErc20DelegateScenario cDAIDelegate"
      `,
      'CErc20DelegateScenario',
      [
        new Arg('name', getStringV),
      ],
      async (
        world,
        { name }
      ) => {
        return {
          invokation: await CErc20DelegateScenarioContract.deploy<CErc20DelegateScenario>(world, from, []),
          name: name.val,
          contract: 'ApeErc20DelegateScenario',
          description: 'Scenario CErc20 Delegate'
        };
      }
    ),

    new Fetcher<{ name: StringV; }, CTokenDelegateData>(
      `
        #### CCollateralCapErc20DelegateScenario
        * "CCollateralCapErc20DelegateScenario name:<String>"
          * E.g. "CTokenDelegate Deploy CCollateralCapErc20DelegateScenario cLinkDelegate"
      `,
      'CCollateralCapErc20DelegateScenario',
      [
        new Arg('name', getStringV),
      ],
      async (
        world,
        { name }
      ) => {
        return {
          invokation: await CCollateralCapErc20DelegateScenarioContract.deploy<CErc20Delegate>(world, from, []),
          name: name.val,
          contract: 'ApeCollateralCapErc20DelegateScenario',
          description: 'Collateral Cap CErc20 Delegate'
        };
      }
    ),

    new Fetcher<{ name: StringV; }, CTokenDelegateData>(
      `
        #### CWrappedNativeDelegateScenario
        * "CWrappedNativeDelegateScenario name:<String>"
          * E.g. "CTokenDelegate Deploy CWrappedNativeDelegateScenario cLinkDelegate"
      `,
      'CWrappedNativeDelegateScenario',
      [
        new Arg('name', getStringV),
      ],
      async (
        world,
        { name }
      ) => {
        return {
          invokation: await CWrappedNativeDelegateScenarioContract.deploy<CErc20Delegate>(world, from, []),
          name: name.val,
          contract: 'ApeWrappedNativeDelegateScenario',
          description: 'Wrapped Native CErc20 Delegate'
        };
      }
    )
  ];

  let delegateData = await getFetcherValue<any, CTokenDelegateData>("DeployCToken", fetchers, world, params);
  let invokation = delegateData.invokation;
  delete delegateData.invokation;

  if (invokation.error) {
    throw invokation.error;
  }

  const cTokenDelegate = invokation.value!;

  world = await storeAndSaveContract(
    world,
    cTokenDelegate,
    delegateData.name,
    invokation,
    [
      {
        index: ['ApeTokenDelegate', delegateData.name],
        data: {
          address: cTokenDelegate._address,
          contract: delegateData.contract,
          description: delegateData.description
        }
      }
    ]
  );

  return { world, cTokenDelegate, delegateData };
}
