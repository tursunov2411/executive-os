import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

export async function getApiUrl() {
  return `${supabaseUrl}/functions/v1/executive-os-api`
}

export async function fetchWithAuth(url: string, options: RequestInit = {}) {
  const { data: { session } } = await supabase.auth.getSession()

  const headers = {
    'Authorization': `Bearer ${session?.access_token || supabaseAnonKey}`,
    'Content-Type': 'application/json',
    'apikey': supabaseAnonKey,
    ...options.headers,
  }

  return fetch(url, { ...options, headers })
}
