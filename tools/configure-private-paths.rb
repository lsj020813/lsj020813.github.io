#!/usr/bin/env ruby

require 'base64'
require 'fileutils'
require 'io/console'
require 'json'
require 'openssl'

def read_required(prompt)
  print prompt
  value = $stdin.gets&.strip
  abort "입력이 비어 있습니다." if value.nil? || value.empty?
  value
end

def normalize_root(value)
  abort "절대경로를 입력해야 합니다." unless value.start_with?('/')
  "#{value.sub(%r{/+\z}, '')}/"
end

project_root = normalize_root(read_required('프로젝트 절대 루트: '))
knih_root = normalize_root(read_required('KNIH 데이터 절대 루트: '))

print '발표 모드 비밀번호: '
password = $stdin.noecho(&:gets)&.chomp
puts
print '비밀번호 확인: '
confirmation = $stdin.noecho(&:gets)&.chomp
puts

abort "비밀번호가 일치하지 않습니다." unless password == confirmation
abort "비밀번호는 12자 이상이어야 합니다." if password.nil? || password.length < 12

mapping = {
  '<PROJECT_ROOT>/' => project_root,
  '<KNIH_DATA_ROOT>/' => knih_root
}

iterations = 310_000
salt = OpenSSL::Random.random_bytes(16)
iv = OpenSSL::Random.random_bytes(12)
key = OpenSSL::KDF.pbkdf2_hmac(password, salt: salt, iterations: iterations, length: 32, hash: 'SHA256')
cipher = OpenSSL::Cipher.new('aes-256-gcm')
cipher.encrypt
cipher.key = key
cipher.iv = iv
ciphertext = cipher.update(JSON.generate(mapping)) + cipher.final
ciphertext << cipher.auth_tag

config = {
  iterations: iterations,
  salt: Base64.strict_encode64(salt),
  iv: Base64.strict_encode64(iv),
  ciphertext: Base64.strict_encode64(ciphertext)
}

output = File.expand_path('../assets/js/private-paths.local.js', __dir__)
FileUtils.mkdir_p(File.dirname(output))
File.write(output, "window.__PRIVATE_PATHS_ENCRYPTED__ = #{JSON.generate(config)};\n", mode: 'w', perm: 0o600)
puts "로컬 암호화 설정을 생성했습니다: #{output}"
puts '이 파일은 .gitignore에 포함되며 commit/push 대상이 아닙니다.'
