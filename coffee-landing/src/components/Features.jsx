import React from 'react'
import { motion } from 'framer-motion'
import { Coffee, ShoppingCart, Clock, CreditCard, Settings, Shield } from 'lucide-react'

const Features = () => {
  const features = [
    {
      icon: Coffee,
      title: 'Каталог напитков',
      description: 'Добавляйте кофе, десерты и напитки с фото и описаниями. Организуйте по категориям. Легко управляйте меню и ценами.',
    },
    {
      icon: ShoppingCart,
      title: 'Онлайн-заказы',
      description: 'Клиенты делают заказы прямо в Telegram Mini App. Вы управляете заказами через админ-панель.',
    },
    {
      icon: Clock,
      title: 'Доставка и самовывоз',
      description: 'Автоматический расчет стоимости доставки через Яндекс Доставку. Поддержка самовывоза.',
    },
    {
      icon: CreditCard,
      title: 'Онлайн-оплата',
      description: 'Интеграция с YooKassa. Принимайте платежи картами онлайн. Безопасные транзакции.',
    },
    {
      icon: Settings,
      title: 'Админ-панель',
      description: 'Управляйте товарами, категориями и заказами через веб-интерфейс. Отслеживайте статусы заказов.',
    },
    {
      icon: Shield,
      title: 'Безопасность',
      description: 'Firebase Authentication для админов. Валидация Telegram для клиентов. Защищенные платежи.',
    },
  ]

  return (
    <section id="features" className="py-20 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Всё для вашей{' '}
            <span className="text-gradient">кофейни</span>
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Полный набор инструментов для управления кофейным бизнесом в Telegram
          </p>
        </motion.div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
          {features.map((feature, index) => (
            <motion.div
              key={feature.title}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              className="bg-gradient-to-br from-coffee-50 to-white p-8 rounded-2xl border border-coffee-100 hover:shadow-xl transition-all"
            >
              <div className="w-14 h-14 bg-gradient-to-br from-coffee-700 via-coffee-800 to-amber-900 rounded-xl flex items-center justify-center mb-4">
                <feature.icon className="w-7 h-7 text-white" />
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-3">
                {feature.title}
              </h3>
              <p className="text-gray-600 leading-relaxed">
                {feature.description}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}

export default Features

