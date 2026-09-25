import { CommissionBasis, Prisma } from '@prisma/client';
export async function recordCommission(tx:Prisma.TransactionClient,args:{tenantId:string;saleId:string;userId:string;revenue:number;grossProfit:number}){
  const profile=await tx.teamProfile.findUnique({where:{tenantId_userId:{tenantId:args.tenantId,userId:args.userId}}});
  if(!profile?.active||!profile.commissionBasis||!profile.commissionRate||profile.commissionRate.lte(0)) return null;
  const base=profile.commissionBasis===CommissionBasis.GROSS_PROFIT?Math.max(0,args.grossProfit):Math.max(0,args.revenue);const amount=new Prisma.Decimal(base).mul(profile.commissionRate).toDecimalPlaces(2);
  return tx.commissionEntry.upsert({where:{saleId_userId:{saleId:args.saleId,userId:args.userId}},create:{tenantId:args.tenantId,saleId:args.saleId,userId:args.userId,basis:profile.commissionBasis,baseAmount:base,rate:profile.commissionRate,amount},update:{basis:profile.commissionBasis,baseAmount:base,rate:profile.commissionRate,amount}});
}
export async function reverseCommissionForRefund(tx:Prisma.TransactionClient,args:{saleId:string;refundAmount:number;saleTotal:number}){if(args.saleTotal<=0)return;const ratio=Math.min(1,Math.max(0,args.refundAmount/args.saleTotal));const entries=await tx.commissionEntry.findMany({where:{saleId:args.saleId}});for(const e of entries){const target=e.amount.mul(ratio);const next=Prisma.Decimal.min(e.amount,e.reversedAmount.plus(target));await tx.commissionEntry.update({where:{id:e.id},data:{reversedAmount:next}});}}
