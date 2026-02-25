import React from 'react'
import { motion } from 'framer-motion'
import {
  ShoppingCart,
  CreditCard,
  Truck,
  Settings,
  BarChart3,
  Smartphone,
  Globe,
  Shield,
} from 'lucide-react'

const Features = () => {
  const features = [
    {
      icon: ShoppingCart,
      title: 'Каталог товаров',
      description: 'Создавайте товары с фото, описаниями и ценами. Организуйте по категориям. Поиск и фильтрация для удобства клиентов.',
      color: 'from-blue-500 to-cyan-500',
    },
    {
      icon: CreditCard,
      title: 'Онлайн оплата',
      description: 'Интеграция с YooKassa. Принимайте платежи картами онлайн. Безопасные транзакции с автоматическим подтверждением.',
      color: 'from-green-500 to-emerald-500',
    },
    {
      icon: Truck,
      title: 'Доставка и самовывоз',
      description: 'Автоматический расчет стоимости доставки через Яндекс.Доставка. Поддержка самовывоза. Автодополнение адресов.',
      color: 'from-orange-500 to-red-500',
    },
    {
      icon: Settings,
      title: 'Админ-панель',
      description: 'Управляйте товарами, категориями и заказами через веб-интерфейс. Отслеживайте статусы заказов в реальном времени.',
      color: 'from-slate-600 to-slate-800',
    },
    {
      icon: Smartphone,
      title: 'Telegram Mini App',
      description: 'Ваш магазин работает прямо в Telegram. Клиенты делают заказы, не покидая мессенджер. Удобный интерфейс для покупок.',
      color: 'from-teal-500 to-cyan-500',
    },
    {
      icon: Shield,
      title: 'Безопасность',
      description: 'Firebase Authentication для админов. Валидация Telegram init_data для клиентов. Защищенные платежи и данные.',
      color: 'from-amber-500 to-yellow-500',
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
            Всё, что нужно для{' '}
            <span className="text-gradient">успешных продаж</span>
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Полнофункциональная платформа со всеми необходимыми инструментами
            для ведения интернет-магазина
          </p>
        </motion.div>

        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
          {features.map((feature, index) => (
            <motion.div
              key={feature.title}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              className="group"
            >
              <div className="bg-white p-6 rounded-2xl border border-gray-200 hover:border-slate-300 hover:shadow-xl transition-all h-full">
                <div
                  className={`w-14 h-14 rounded-xl bg-gradient-to-br ${feature.color} p-3 mb-4 group-hover:scale-110 transition-transform`}
                >
                  <feature.icon className="w-full h-full text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-2">
                  {feature.title}
                </h3>
                <p className="text-gray-600 leading-relaxed">
                  {feature.description}
                </p>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}

export default Features

