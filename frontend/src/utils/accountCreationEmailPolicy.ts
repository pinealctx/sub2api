const EMAIL_SUFFIX_TOKEN_SPLIT_RE = /[\s,，]+/
const EMAIL_SUFFIX_INVALID_CHAR_RE = /[^a-z0-9.-]/g
const EMAIL_SUFFIX_INVALID_CHAR_CHECK_RE = /[^a-z0-9.-]/
const EMAIL_SUFFIX_PREFIX_RE = /^@+/
const EMAIL_SUFFIX_WILDCARD_PREFIX = '*.'
const EMAIL_SUFFIX_MESSAGE_VISIBLE_LIMIT = 5
const EMAIL_SUFFIX_DOMAIN_PATTERN =
  /^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$/

// normalizeAccountCreationEmailSuffixDomain converts raw input into a canonical domain token.
// Exact domains are returned without "@"; wildcard domains keep the "*." prefix.
export function normalizeAccountCreationEmailSuffixDomain(raw: string): string {
  let value = String(raw || '').trim().toLowerCase()
  if (!value) {
    return ''
  }

  value = value.replace(EMAIL_SUFFIX_PREFIX_RE, '')
  return normalizeAccountCreationEmailSuffixToken(value, false)
}

export function normalizeAccountCreationEmailSuffixDomains(
  items: string[] | null | undefined
): string[] {
  if (!items || items.length === 0) {
    return []
  }

  const seen = new Set<string>()
  const normalized: string[] = []
  for (const item of items) {
    const domain = normalizeAccountCreationEmailSuffixDomain(item)
    if (!isAccountCreationEmailSuffixDomainValid(domain) || seen.has(domain)) {
      continue
    }
    seen.add(domain)
    normalized.push(domain)
  }
  return normalized
}

export function parseAccountCreationEmailSuffixWhitelistInput(input: string): string[] {
  if (!input || !input.trim()) {
    return []
  }

  const seen = new Set<string>()
  const normalized: string[] = []

  for (const token of input.split(EMAIL_SUFFIX_TOKEN_SPLIT_RE)) {
    const domain = normalizeAccountCreationEmailSuffixDomainStrict(token)
    if (!isAccountCreationEmailSuffixDomainValid(domain) || seen.has(domain)) {
      continue
    }
    seen.add(domain)
    normalized.push(domain)
  }

  return normalized
}

export function normalizeAccountCreationEmailSuffixWhitelist(
  items: string[] | null | undefined
): string[] {
  return normalizeAccountCreationEmailSuffixDomains(items).map(toCanonicalAccountCreationEmailSuffix)
}

function extractAccountCreationEmailDomain(email: string): string {
  const raw = String(email || '').trim().toLowerCase()
  if (!raw) {
    return ''
  }
  const atIndex = raw.indexOf('@')
  if (atIndex <= 0 || atIndex >= raw.length - 1) {
    return ''
  }
  if (raw.indexOf('@', atIndex + 1) !== -1) {
    return ''
  }
  return raw.slice(atIndex + 1)
}

export function isAccountCreationEmailSuffixAllowed(
  email: string,
  whitelist: string[] | null | undefined
): boolean {
  const normalizedWhitelist = normalizeAccountCreationEmailSuffixWhitelist(whitelist)
  if (normalizedWhitelist.length === 0) {
    return true
  }
  const emailDomain = extractAccountCreationEmailDomain(email)
  if (!emailDomain) {
    return false
  }
  const emailSuffix = `@${emailDomain}`
  return normalizedWhitelist.some((allowed) => {
    if (allowed.startsWith('@')) {
      return allowed === emailSuffix
    }
    if (allowed.startsWith(EMAIL_SUFFIX_WILDCARD_PREFIX)) {
      const base = allowed.slice(EMAIL_SUFFIX_WILDCARD_PREFIX.length)
      return emailDomain === base || emailDomain.endsWith(`.${base}`)
    }
    return false
  })
}

export function formatAccountCreationEmailSuffixWhitelistForMessage(
  whitelist: string[] | null | undefined,
  options: {
    separator: string
    more: (count: number) => string
  }
): string {
  const normalizedWhitelist = normalizeAccountCreationEmailSuffixWhitelist(whitelist)
  const visible = normalizedWhitelist.slice(0, EMAIL_SUFFIX_MESSAGE_VISIBLE_LIMIT)
  const hiddenCount = normalizedWhitelist.length - visible.length
  if (hiddenCount > 0) {
    visible.push(options.more(hiddenCount))
  }
  return visible.join(options.separator)
}

// Pasted domains should be strict: any invalid character drops the whole token.
function normalizeAccountCreationEmailSuffixDomainStrict(raw: string): string {
  let value = String(raw || '').trim().toLowerCase()
  if (!value) {
    return ''
  }
  value = value.replace(EMAIL_SUFFIX_PREFIX_RE, '')
  return normalizeAccountCreationEmailSuffixToken(value, true)
}

export function isAccountCreationEmailSuffixDomainValid(domain: string): boolean {
  if (!domain) {
    return false
  }
  if (domain.startsWith(EMAIL_SUFFIX_WILDCARD_PREFIX)) {
    return EMAIL_SUFFIX_DOMAIN_PATTERN.test(domain.slice(EMAIL_SUFFIX_WILDCARD_PREFIX.length))
  }
  return !domain.includes('*') && EMAIL_SUFFIX_DOMAIN_PATTERN.test(domain)
}

function normalizeAccountCreationEmailSuffixToken(value: string, strict: boolean): string {
  if (value.startsWith(EMAIL_SUFFIX_WILDCARD_PREFIX)) {
    const domain = value.slice(EMAIL_SUFFIX_WILDCARD_PREFIX.length)
    if (strict && (!domain || EMAIL_SUFFIX_INVALID_CHAR_CHECK_RE.test(domain))) {
      return ''
    }
    return `${EMAIL_SUFFIX_WILDCARD_PREFIX}${domain.replace(EMAIL_SUFFIX_INVALID_CHAR_RE, '')}`
  }

  if (value === '*') {
    return strict ? '' : value
  }

  if (strict && EMAIL_SUFFIX_INVALID_CHAR_CHECK_RE.test(value)) {
    return ''
  }
  return value.replace(/[*]/g, '').replace(EMAIL_SUFFIX_INVALID_CHAR_RE, '')
}

function toCanonicalAccountCreationEmailSuffix(domain: string): string {
  return domain.startsWith(EMAIL_SUFFIX_WILDCARD_PREFIX) ? domain : `@${domain}`
}
