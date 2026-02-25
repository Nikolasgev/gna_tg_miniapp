import React from 'react'
import { motion } from 'framer-motion'
import { Settings, ShoppingBag, Package, ListChecks } from 'lucide-react'

const AdminPanel = () => {
  const adminFeatures = [
    {
      icon: Package,
      title: 'Управление товарами',
      description: 'Добавляйте, редактируйте и удаляйте товары. Загружайте фото, устанавливайте цены, создавайте категории.',
    },
    {
      icon: ShoppingBag,
      title: 'Управление заказами',
      description: 'Просматривайте все заказы, меняйте статусы, отслеживайте оплату. Полная история заказов.',
    },
    {
      icon: Settings,
      title: 'Настройки бизнеса',
      description: 'Настройте название, логотип, валюту и тему. Подключите оплату и доставку.',
    },
    {
      icon: ListChecks,
      title: 'Управление категориями',
      description: 'Создавайте категории для организации товаров. Настраивайте порядок отображения.',
    },
  ]

  return (
    <section id="admin" className="py-20 bg-gradient-to-br from-coffee-50 to-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Админ-панель{' '}
            <span className="text-gradient">для управления</span>
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Удобный веб-интерфейс для управления вашей кофейней. Все инструменты в одном месте.
          </p>
        </motion.div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
          {adminFeatures.map((feature, index) => (
            <motion.div
              key={feature.title}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              className="bg-white rounded-2xl p-6 shadow-lg hover:shadow-xl transition-all border border-coffee-100"
            >
              <div className="w-14 h-14 bg-gradient-to-br from-coffee-600 to-coffee-800 rounded-xl flex items-center justify-center mb-4">
                <feature.icon className="w-7 h-7 text-white" />
              </div>
              <h3 className="text-lg font-bold text-gray-900 mb-2">
                {feature.title}
              </h3>
              <p className="text-gray-600 text-sm leading-relaxed">
                {feature.description}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}

export default AdminPanel

