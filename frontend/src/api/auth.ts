/**
 * Authentication API endpoints
 * Handles user login, OIDC account creation, and logout operations
 */

import { apiClient } from './client'
import type {
  LoginRequest,
  AuthResponse,
  CurrentUserResponse,
  EmailVerifyCodeRequest,
  EmailVerifyCodeResponse,
  PublicSettings,
  TotpLoginResponse,
  TotpLogin2FARequest
} from '@/types'

/**
 * Login response type - can be either full auth or 2FA required
 */
export type LoginResponse = AuthResponse | TotpLoginResponse

/**
 * Type guard to check if login response requires 2FA
 */
export function isTotp2FARequired(response: LoginResponse): response is TotpLoginResponse {
  return 'requires_2fa' in response && response.requires_2fa === true
}

/**
 * Store authentication token in localStorage
 */
export function setAuthToken(token: string): void {
  localStorage.setItem('auth_token', token)
}

/**
 * Store refresh token in localStorage
 */
export function setRefreshToken(token: string): void {
  localStorage.setItem('refresh_token', token)
}

/**
 * Store token expiration timestamp in localStorage
 * Converts expires_in (seconds) to absolute timestamp (milliseconds)
 */
export function setTokenExpiresAt(expiresIn: number): void {
  const expiresAt = Date.now() + expiresIn * 1000
  localStorage.setItem('token_expires_at', String(expiresAt))
}

/**
 * Get authentication token from localStorage
 */
export function getAuthToken(): string | null {
  return localStorage.getItem('auth_token')
}

/**
 * Get refresh token from localStorage
 */
export function getRefreshToken(): string | null {
  return localStorage.getItem('refresh_token')
}

/**
 * Get token expiration timestamp from localStorage
 */
export function getTokenExpiresAt(): number | null {
  const value = localStorage.getItem('token_expires_at')
  return value ? parseInt(value, 10) : null
}

/**
 * Clear authentication token from localStorage
 */
export function clearAuthToken(): void {
  localStorage.removeItem('auth_token')
  localStorage.removeItem('refresh_token')
  localStorage.removeItem('auth_user')
  localStorage.removeItem('token_expires_at')
}

/**
 * User login
 * @param credentials - Email and password
 * @returns Authentication response with token and user data, or 2FA required response
 */
export async function login(credentials: LoginRequest): Promise<LoginResponse> {
  const { data } = await apiClient.post<LoginResponse>('/auth/login', credentials)

  // Only store token if 2FA is not required
  if (!isTotp2FARequired(data)) {
    setAuthToken(data.access_token)
    if (data.refresh_token) {
      setRefreshToken(data.refresh_token)
    }
    if (data.expires_in) {
      setTokenExpiresAt(data.expires_in)
    }
    localStorage.setItem('auth_user', JSON.stringify(data.user))
  }

  return data
}

/**
 * Complete login with 2FA code
 * @param request - Temp token and TOTP code
 * @returns Authentication response with token and user data
 */
export async function login2FA(request: TotpLogin2FARequest): Promise<AuthResponse> {
  const { data } = await apiClient.post<AuthResponse>('/auth/login/2fa', request)

  // Store token and user data
  setAuthToken(data.access_token)
  if (data.refresh_token) {
    setRefreshToken(data.refresh_token)
  }
  if (data.expires_in) {
    setTokenExpiresAt(data.expires_in)
  }
  localStorage.setItem('auth_user', JSON.stringify(data.user))

  return data
}

/**
 * Get current authenticated user
 * @returns User profile data
 */
export async function getCurrentUser() {
  return apiClient.get<CurrentUserResponse>('/auth/me')
}

/**
 * User logout
 * Clears authentication token and user data from localStorage
 * Optionally revokes the refresh token on the server
 */
export async function logout(): Promise<void> {
  const refreshToken = getRefreshToken()

  // Try to revoke the refresh token on the server
  if (refreshToken) {
    try {
      await apiClient.post('/auth/logout', { refresh_token: refreshToken })
    } catch {
      // Ignore errors - we still want to clear local state
    }
  }

  clearAuthToken()
}

/**
 * Refresh token response
 */
export interface RefreshTokenResponse {
  access_token: string
  refresh_token: string
  expires_in: number
  token_type: string
}

export interface OAuthTokenResponse {
  access_token: string
  refresh_token?: string
  expires_in?: number
  token_type?: string
}

export interface PendingOAuthBindLoginResponse extends Partial<OAuthTokenResponse> {
  auth_result?: string
  redirect?: string
  error?: string
  requires_2fa?: boolean
  temp_token?: string
  user_email_masked?: string
  adoption_required?: boolean
  suggested_display_name?: string
  suggested_avatar_url?: string
}

export type PendingOAuthExchangeResponse = PendingOAuthBindLoginResponse

export interface PendingOAuthCreateAccountResponse extends OAuthTokenResponse {
  auth_result?: string
}

export interface PendingOAuthEmailVerifyCodeResponse extends EmailVerifyCodeResponse {
  auth_result?: string
  provider?: string
  redirect?: string
}

export type OAuthCompletionKind = 'login' | 'bind'

export interface OAuthAdoptionDecision {
  adoptDisplayName?: boolean
  adoptAvatar?: boolean
}

function serializeOAuthAdoptionDecision(
  decision?: OAuthAdoptionDecision
): Record<string, boolean> {
  const payload: Record<string, boolean> = {}

  if (typeof decision?.adoptDisplayName === 'boolean') {
    payload.adopt_display_name = decision.adoptDisplayName
  }
  if (typeof decision?.adoptAvatar === 'boolean') {
    payload.adopt_avatar = decision.adoptAvatar
  }

  return payload
}

export function isOAuthLoginCompletion(
  completion: Partial<OAuthTokenResponse>
): completion is OAuthTokenResponse {
  return typeof completion.access_token === 'string' && completion.access_token.trim().length > 0
}

export function getOAuthCompletionKind(
  completion: Partial<OAuthTokenResponse>
): OAuthCompletionKind {
  return isOAuthLoginCompletion(completion) ? 'login' : 'bind'
}

export function getPendingOAuthBindLoginKind(
  completion: PendingOAuthBindLoginResponse
): OAuthCompletionKind {
  return getOAuthCompletionKind(completion)
}

export function isPendingOAuthCreateAccountRequired(
  completion: Pick<PendingOAuthBindLoginResponse, 'error'>
): boolean {
  return completion.error === 'invitation_required'
}

export function hasPendingOAuthSuggestedProfile(
  completion: Pick<
    PendingOAuthBindLoginResponse,
    'suggested_display_name' | 'suggested_avatar_url'
  >
): boolean {
  return Boolean(completion.suggested_display_name || completion.suggested_avatar_url)
}

export function persistOAuthTokenContext(tokens: Partial<OAuthTokenResponse>): void {
  if (tokens.refresh_token) {
    setRefreshToken(tokens.refresh_token)
  }
  if (tokens.expires_in) {
    setTokenExpiresAt(tokens.expires_in)
  }
}

export async function prepareOAuthBindAccessTokenCookie(): Promise<void> {
  if (!getAuthToken()) {
    return
  }
  await apiClient.post('/auth/oauth/bind-token')
}

/**
 * Refresh the access token using the refresh token
 * @returns New token pair
 */
export async function refreshToken(): Promise<RefreshTokenResponse> {
  const currentRefreshToken = getRefreshToken()
  if (!currentRefreshToken) {
    throw new Error('No refresh token available')
  }

  const { data } = await apiClient.post<RefreshTokenResponse>('/auth/refresh', {
    refresh_token: currentRefreshToken
  })

  // Update tokens in localStorage
  setAuthToken(data.access_token)
  setRefreshToken(data.refresh_token)
  setTokenExpiresAt(data.expires_in)

  return data
}

/**
 * Revoke all sessions for the current user
 * @returns Response with message
 */
export async function revokeAllSessions(): Promise<{ message: string }> {
  const { data } = await apiClient.post<{ message: string }>('/auth/revoke-all-sessions')
  return data
}

/**
 * Check if user is authenticated
 * @returns True if user has valid token
 */
export function isAuthenticated(): boolean {
  return getAuthToken() !== null
}

/**
 * Get public settings (no auth required)
 * @returns Public settings including OIDC account creation and Turnstile config
 */
export async function getPublicSettings(): Promise<PublicSettings> {
  const { data } = await apiClient.get<PublicSettings>('/settings/public')
  return data
}

export async function sendPendingOAuthVerifyCode(
  request: EmailVerifyCodeRequest
): Promise<PendingOAuthEmailVerifyCodeResponse> {
  const { data } = await apiClient.post<PendingOAuthEmailVerifyCodeResponse>(
    '/auth/oauth/pending/send-verify-code',
    request
  )
  return data
}

/**
 * Complete OIDC OAuth account creation by supplying an invitation code
 * @param invitationCode - Invitation code entered by the user
 * @returns Token pair on success
 */
export async function completeOIDCOAuthAccountCreation(
  invitationCode: string,
  decision?: OAuthAdoptionDecision
): Promise<OAuthTokenResponse> {
  return createPendingOIDCOAuthAccount(invitationCode, decision)
}

async function createPendingOAuthAccount(
  provider: 'oidc',
  invitationCode: string,
  decision?: OAuthAdoptionDecision
): Promise<PendingOAuthCreateAccountResponse> {
  const { data } = await apiClient.post<PendingOAuthCreateAccountResponse>(
    `/auth/oauth/${provider}/complete-registration`,
    {
      invitation_code: invitationCode,
      ...serializeOAuthAdoptionDecision(decision)
    }
  )
  return data
}

export async function createPendingOIDCOAuthAccount(
  invitationCode: string,
  decision?: OAuthAdoptionDecision
): Promise<PendingOAuthCreateAccountResponse> {
  return createPendingOAuthAccount('oidc', invitationCode, decision)
}

export async function completePendingOAuthBindLogin(
  decision?: OAuthAdoptionDecision
): Promise<PendingOAuthBindLoginResponse> {
  const { data } = await apiClient.post<PendingOAuthBindLoginResponse>(
    '/auth/oauth/pending/exchange',
    serializeOAuthAdoptionDecision(decision)
  )
  return data
}

export async function exchangePendingOAuthCompletion(
  decision?: OAuthAdoptionDecision
): Promise<PendingOAuthExchangeResponse> {
  return completePendingOAuthBindLogin(decision)
}

export const authAPI = {
  login,
  login2FA,
  isTotp2FARequired,
  getCurrentUser,
  logout,
  isAuthenticated,
  setAuthToken,
  setRefreshToken,
  setTokenExpiresAt,
  getAuthToken,
  getRefreshToken,
  getTokenExpiresAt,
  clearAuthToken,
  getPublicSettings,
  sendPendingOAuthVerifyCode,
  refreshToken,
  revokeAllSessions,
  getPendingOAuthBindLoginKind,
  isPendingOAuthCreateAccountRequired,
  hasPendingOAuthSuggestedProfile,
  completePendingOAuthBindLogin,
  createPendingOIDCOAuthAccount,
  exchangePendingOAuthCompletion,
  completeOIDCOAuthAccountCreation,
}

export default authAPI
