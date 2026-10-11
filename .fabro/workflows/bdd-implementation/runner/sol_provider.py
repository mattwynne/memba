"""Trusted Pi SDK identity/command gate; no model calls or credential reads."""
import hashlib
from pathlib import Path
import re

from candidate import Blocked, digest


def runtime_digest(root):
    root = Path(root).resolve()
    files = {}
    for p in sorted(root.rglob('*')):
        if p.is_symlink():
            # Package-manager bin links are not imported; bind their destinations.
            files[str(p.relative_to(root))] = {'link': str(p.readlink())}
        elif p.is_file():
            files[str(p.relative_to(root))] = hashlib.sha256(p.read_bytes()).hexdigest()
    return digest(files)


def validate_provider(c, verify=False):
    if c.get('model_backend') != 'pi-sol':
        return  # Historical CLI/process-double contracts; never silently migrate them.
    p = c.get('sol_provider', {})
    required = {'sdk_root', 'sdk_digest', 'node', 'node_sha256', 'model_digest',
                'provider', 'api', 'base_url', 'max_turns', 'thinking'}
    legacy = set(p) == required | {'visit_token_limit'}
    accounting_only = set(p) == required | {'token_policy'} and p.get('token_policy') == 'accounting-only'
    if not (legacy or accounting_only) or c.get('claude') or c.get('model') != 'gpt-6.1-sol':
        raise Blocked('Explicit Sol provider contract required; no alternate CLI/model')
    if (p['provider'], p['api'], p['base_url']) != (
            'openai-codex', 'openai-codex-responses', 'https://chatgpt.com/backend-api'):
        raise Blocked('Unsupported Sol provider identity')
    if p['thinking'] not in ('low', 'medium', 'high', 'xhigh', 'max'):
        raise Blocked('Invalid Sol thinking level')
    for key, maximum in [('max_turns', 160)] + ([('visit_token_limit', 2000000)] if legacy else []):
        if type(p[key]) is not int or not 0 < p[key] <= maximum:
            raise Blocked('Invalid finite Sol budget: ' + key)
    if c.get('visit_usd') is not None:
        raise Blocked('Sol has no supported hard CLI dollar cap; visit_usd must be null')
    for key in ['sdk_digest', 'node_sha256', 'model_digest']:
        if not isinstance(p[key], str) or not re.fullmatch('[0-9a-f]{64}', p[key]):
            raise Blocked('Invalid Sol runtime fingerprint')
    if not Path(p['sdk_root']).is_absolute() or not Path(p['node']).is_absolute():
        raise Blocked('Absolute trusted Sol runtime paths required')
    if verify:
        if runtime_digest(p['sdk_root']) != p['sdk_digest']:
            raise Blocked('Sol SDK runtime changed')
        if hashlib.sha256(Path(p['node']).read_bytes()).hexdigest() != p['node_sha256']:
            raise Blocked('Sol Node runtime changed')


def model_command(c, job, attempt, role, prefix, system_prompt, resume):
    validate_provider(c, verify=True)
    if c.get('model_backend') != 'pi-sol':
        raise Blocked('Not a Sol contract')
    return [c['sol_provider']['node'], str(Path(job) / 'sol_adapter.mjs'),
            str(Path(job)), attempt, role, str(prefix), 'resume' if resume else 'new', system_prompt]
