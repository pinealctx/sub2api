import { describe, expect, it } from 'vitest'
import {
  formatAccountCreationEmailSuffixWhitelistForMessage,
  isAccountCreationEmailSuffixAllowed,
  isAccountCreationEmailSuffixDomainValid,
  normalizeAccountCreationEmailSuffixDomain,
  normalizeAccountCreationEmailSuffixDomains,
  normalizeAccountCreationEmailSuffixWhitelist,
  parseAccountCreationEmailSuffixWhitelistInput
} from '@/utils/accountCreationEmailPolicy'

describe('accountCreationEmailPolicy utils', () => {
  it('normalizeAccountCreationEmailSuffixDomain lowercases, strips @, and ignores invalid chars', () => {
    expect(normalizeAccountCreationEmailSuffixDomain(' @Exa!mple.COM ')).toBe('example.com')
    expect(normalizeAccountCreationEmailSuffixDomain(' *.EDU!.CN ')).toBe('*.edu.cn')
  })

  it('normalizeAccountCreationEmailSuffixDomains deduplicates normalized domains', () => {
    expect(
      normalizeAccountCreationEmailSuffixDomains([
        '@example.com',
        'Example.com',
        '',
        '-invalid.com',
        'foo..bar.com',
        ' @foo.bar ',
        '@foo.bar',
        '*.EDU.CN',
        '*.edu.cn'
      ])
    ).toEqual(['example.com', 'foo.bar', '*.edu.cn'])
  })

  it('parseAccountCreationEmailSuffixWhitelistInput supports separators and deduplicates', () => {
    const input = '\n  @example.com,example.com，@foo.bar\t@FOO.bar *.EDU.CN  '
    expect(parseAccountCreationEmailSuffixWhitelistInput(input)).toEqual([
      'example.com',
      'foo.bar',
      '*.edu.cn'
    ])
  })

  it('parseAccountCreationEmailSuffixWhitelistInput drops tokens containing invalid chars', () => {
    const input = '@exa!mple.com, @foo.bar, @bad#token.com, @ok-domain.com'
    expect(parseAccountCreationEmailSuffixWhitelistInput(input)).toEqual(['foo.bar', 'ok-domain.com'])
  })

  it('parseAccountCreationEmailSuffixWhitelistInput drops structurally invalid domains', () => {
    const input = '@-bad.com, @foo..bar.com, @foo.bar, @xn--ok.com, *., *, *.@, *.foo'
    expect(parseAccountCreationEmailSuffixWhitelistInput(input)).toEqual(['foo.bar', 'xn--ok.com'])
  })

  it('parseAccountCreationEmailSuffixWhitelistInput returns empty list for blank input', () => {
    expect(parseAccountCreationEmailSuffixWhitelistInput('   \n \n')).toEqual([])
  })

  it('normalizeAccountCreationEmailSuffixWhitelist returns canonical @domain list', () => {
    expect(
      normalizeAccountCreationEmailSuffixWhitelist([
        '@Example.com',
        'foo.bar',
        '',
        '-invalid.com',
        ' @foo.bar ',
        '*.EDU.CN'
      ])
    ).toEqual(['@example.com', '@foo.bar', '*.edu.cn'])
  })

  it('isAccountCreationEmailSuffixDomainValid matches backend-compatible domain rules', () => {
    expect(isAccountCreationEmailSuffixDomainValid('example.com')).toBe(true)
    expect(isAccountCreationEmailSuffixDomainValid('foo-bar.example.com')).toBe(true)
    expect(isAccountCreationEmailSuffixDomainValid('*.edu.cn')).toBe(true)
    expect(isAccountCreationEmailSuffixDomainValid('-bad.com')).toBe(false)
    expect(isAccountCreationEmailSuffixDomainValid('foo..bar.com')).toBe(false)
    expect(isAccountCreationEmailSuffixDomainValid('localhost')).toBe(false)
    expect(isAccountCreationEmailSuffixDomainValid('*.foo')).toBe(false)
    expect(isAccountCreationEmailSuffixDomainValid('*')).toBe(false)
    expect(isAccountCreationEmailSuffixDomainValid('*.@')).toBe(false)
  })

  it('isAccountCreationEmailSuffixAllowed allows any email when whitelist is empty', () => {
    expect(isAccountCreationEmailSuffixAllowed('user@example.com', [])).toBe(true)
  })

  it('isAccountCreationEmailSuffixAllowed applies exact suffix matching', () => {
    expect(isAccountCreationEmailSuffixAllowed('user@example.com', ['@example.com'])).toBe(true)
    expect(isAccountCreationEmailSuffixAllowed('user@sub.example.com', ['@example.com'])).toBe(false)
    expect(isAccountCreationEmailSuffixAllowed('user@qq.com', ['@qq.com'])).toBe(true)
    expect(isAccountCreationEmailSuffixAllowed('user@sub.qq.com', ['@qq.com'])).toBe(false)
  })

  it('isAccountCreationEmailSuffixAllowed applies wildcard suffix matching', () => {
    expect(isAccountCreationEmailSuffixAllowed('student@cs.edu.cn', ['*.edu.cn'])).toBe(true)
    expect(isAccountCreationEmailSuffixAllowed('student@edu.cn', ['*.edu.cn'])).toBe(true)
    expect(isAccountCreationEmailSuffixAllowed('student@foo.cn', ['*.edu.cn'])).toBe(false)
  })

  it('isAccountCreationEmailSuffixAllowed supports mixed exact and wildcard entries', () => {
    const whitelist = ['@a.com', '*.b.cn']
    expect(isAccountCreationEmailSuffixAllowed('user@a.com', whitelist)).toBe(true)
    expect(isAccountCreationEmailSuffixAllowed('user@school.b.cn', whitelist)).toBe(true)
    expect(isAccountCreationEmailSuffixAllowed('user@b.cn', whitelist)).toBe(true)
    expect(isAccountCreationEmailSuffixAllowed('user@c.cn', whitelist)).toBe(false)
  })

  it('formatAccountCreationEmailSuffixWhitelistForMessage lists up to five entries', () => {
    expect(
      formatAccountCreationEmailSuffixWhitelistForMessage(
        ['@a.com', '@b.com', '@c.com', '@d.com', '@e.com'],
        { separator: ', ', more: (count) => `and ${count} more` }
      )
    ).toBe('@a.com, @b.com, @c.com, @d.com, @e.com')
    expect(
      formatAccountCreationEmailSuffixWhitelistForMessage(
        ['@a.com', '@b.com', '@c.com', '@d.com', '@e.com', '*.edu.cn', '@f.com'],
        { separator: ', ', more: (count) => `and ${count} more` }
      )
    ).toBe('@a.com, @b.com, @c.com, @d.com, @e.com, and 2 more')
  })
})
