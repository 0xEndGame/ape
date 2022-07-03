import { Contract } from '../Contract';
import { Sendable } from '../Invokation';

export interface CompoundLensMethods {
  apeTokenBalances(cToken: string, account: string): Sendable<[string,number,number,number,number,number]>;
  apeTokenBalancesAll(cTokens: string[], account: string): Sendable<[string,number,number,number,number,number][]>;
  apeTokenMetadata(cToken: string): Sendable<[string,number,number,number,number,number,number,number,number,boolean,number,string,number,number]>;
  apeTokenMetadataAll(cTokens: string[]): Sendable<[string,number,number,number,number,number,number,number,number,boolean,number,string,number,number][]>;
  getAccountLimits(comptroller: string, account: string): Sendable<[string[],number,number]>;
}

export interface CompoundLens extends Contract {
  methods: CompoundLensMethods;
  name: string;
}
