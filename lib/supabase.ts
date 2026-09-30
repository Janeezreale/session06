import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY?.trim();

function isValidConfig() {
  if (!url || !key || !/^sb_publishable_[A-Za-z0-9_-]+$/.test(key)) return false;
  try {
    const parsed = new URL(url);
    return parsed.protocol === "https:" && parsed.hostname.endsWith(".supabase.co")
      && parsed.pathname === "/" && !parsed.search && !parsed.hash
      && !parsed.username && !parsed.password;
  } catch {
    return false;
  }
}

// 공개 키는 브라우저에 포함됩니다. 데이터 권한은 DB의 RLS로 제한합니다.
export const configError = isValidConfig() ? null
  : ".env.local에 새 Supabase 프로젝트의 https://…supabase.co URL과 sb_publishable_로 시작하는 publishable key를 입력하세요. 변경 후 개발 서버를 다시 시작하세요. 배포 환경에서는 환경변수 등록 후 재배포하세요.";

let client: SupabaseClient | null = null;
export function getSupabase() {
  if (configError || !url || !key) throw new Error("Supabase 설정을 확인해 주세요.");
  client ??= createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
  });
  return client;
}
