export const PRECISION = 1000000000000n;
// mirrors Pair::calculate_exchange_rate
export function calculateExchangeRate(lastTs, nowTs, intervalRate, lastRate, spi) {
  lastTs = BigInt(lastTs); nowTs = BigInt(nowTs); intervalRate = BigInt(intervalRate);
  lastRate = BigInt(lastRate); spi = BigInt(spi);
  if (nowTs === lastTs) return lastRate;
  if (nowTs < lastTs) return null;
  const elapsed = nowTs - lastTs;
  const n = elapsed / spi;
  const rem = elapsed % spi;
  let compounded = PRECISION;
  for (let i = 0n; i < n; i++) compounded = (compounded * intervalRate) / PRECISION;
  const linear = ((intervalRate - PRECISION) * rem) / spi;
  const total = compounded + linear;
  return (lastRate * total) / PRECISION;
}
export function baseToLst(amount, rate, baseDec=6, lstDec=6) {
  amount = BigInt(amount); rate = BigInt(rate);
  let c = (amount * PRECISION) / rate;
  if (lstDec > baseDec) c = c * 10n ** BigInt(lstDec - baseDec);
  else if (baseDec > lstDec) c = c / 10n ** BigInt(baseDec - lstDec);
  return c;
}
export function lstToBase(amount, rate, baseDec=6, lstDec=6) {
  amount = BigInt(amount); rate = BigInt(rate);
  let c = (amount * rate) / PRECISION;
  if (baseDec > lstDec) c = c * 10n ** BigInt(baseDec - lstDec);
  else if (lstDec > baseDec) c = c / 10n ** BigInt(lstDec - baseDec);
  return c;
}
