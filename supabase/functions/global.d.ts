// Ambient type declarations untuk runtime Deno dan URL modules di Supabase Edge Functions.

declare namespace Deno {
  export interface Env {
    get(key: string): string | undefined;
    set(key: string, value: string): void;
    delete(key: string): void;
    toObject(): Record<string, string>;
  }
  export const env: Env;
}

declare module "https://deno.land/std@0.168.0/http/server.ts" {
  export function serve(
    handler: (req: Request) => Promise<Response> | Response
  ): void;
}

declare module "https://esm.sh/@supabase/supabase-js@2.39.0" {
  export function createClient(
    supabaseUrl: string,
    supabaseKey: string,
    options?: any
  ): any;
  export type SupabaseClient = any;
}

declare module "https://*" {
  const content: any;
  export default content;
  export const serve: any;
  export const createClient: any;
}
