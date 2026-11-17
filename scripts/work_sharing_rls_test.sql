-- Run only in an isolated local test database with the migration applied.
\set ON_ERROR_STOP on
begin;
do $$begin if current_database() not like 'najd_sharing_qa_%' then raise exception 'ISOLATED_TEST_DATABASE_REQUIRED'; end if; end$$;
insert into auth.users(id,is_anonymous,email_confirmed_at) values
 ('11111111-1111-4111-8111-111111111111',false,now()),
 ('22222222-2222-4222-8222-222222222222',false,now()),
 ('33333333-3333-4333-8333-333333333333',false,now()),
 ('44444444-4444-4444-8444-444444444444',true,null);
set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
select public.najd_share_work('22222222-2222-4222-8222-222222222222', '{"content_ref":"tmdb:movie:1","title":"Fixture","position_ms":12000}') as share_id \gset
select set_config('test.share_id', :'share_id', true);
do $$begin
 begin perform public.najd_share_work('22222222-2222-4222-8222-222222222222','{"content_ref":"tmdb:movie:1","title":"Bad","position_ms":0,"headers":{"Cookie":"private"}}'); raise exception 'UNSAFE_PAYLOAD_ACCEPTED';
 exception when others then if sqlerrm<>'INVALID_SHARE_PAYLOAD' then raise; end if; end;
 begin perform public.najd_share_respond(current_setting('test.share_id')::uuid,true); raise exception 'SENDER_ACCEPTED';
 exception when others then if sqlerrm<>'SHARE_NOT_PENDING' then raise; end if; end;
 if (select count(*) from public.najd_shared_works())<>0 then raise exception 'UNACCEPTED_VISIBLE'; end if;
end $$;
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
do $$begin
 if (select count(*) from public.najd_work_shares)<>0 then raise exception 'RLS_LEAK'; end if;
 begin perform public.najd_share_respond(current_setting('test.share_id')::uuid,true); raise exception 'STRANGER_ACCEPTED';
 exception when others then if sqlerrm<>'SHARE_NOT_PENDING' then raise; end if; end;
 begin insert into public.najd_work_shares(sender_id,recipient_id,payload) values(auth.uid(),'11111111-1111-4111-8111-111111111111','{}'); raise exception 'DIRECT_INSERT_ALLOWED';
 exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub','44444444-4444-4444-8444-444444444444',true);
do $$begin
 begin perform public.najd_share_work('22222222-2222-4222-8222-222222222222','{"content_ref":"tmdb:movie:1","title":"Bad","position_ms":0}'); raise exception 'ANONYMOUS_SENT';
 exception when others then if sqlerrm<>'REGISTERED_ACCOUNT_REQUIRED' then raise; end if; end;
end $$;
select set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
do $$begin
 if (select count(*) from public.najd_share_inbox())<>1 then raise exception 'RECIPIENT_INBOX_MISSING'; end if;
 perform public.najd_share_respond(current_setting('test.share_id')::uuid,true);
 if (select count(*) from public.najd_shared_works())<>1 then raise exception 'ACCEPTED_SHARE_MISSING'; end if;
 if (select count(*) from public.najd_share_inbox())<>0 then raise exception 'ACK_NOT_DURABLE'; end if;
 begin perform public.najd_share_respond(current_setting('test.share_id')::uuid,false); raise exception 'REPLAY_ACCEPTED';
 exception when others then if sqlerrm<>'SHARE_NOT_PENDING' then raise; end if; end;
end $$;
reset role;
rollback;
\echo PASS sharing owner isolation, recipient consent, durable acknowledgement, replay rejection, anonymous rejection and credential guard
