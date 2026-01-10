import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 Seeding database...')

  // サンプルユーザーを作成
  const users = await prisma.user.createMany({
    data: [
      { email: 'user1@example.com', name: 'User 1' },
      { email: 'user2@example.com', name: 'User 2' },
      { email: 'user3@example.com', name: 'User 3' },
    ],
    skipDuplicates: true,
  })

  console.log(`✅ Created ${users.count} users`)
  console.log('🎉 Seeding completed!')
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
